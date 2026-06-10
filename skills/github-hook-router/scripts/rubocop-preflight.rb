#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop-preflight.rb
#
# Lightweight gatekeeper for GitHub check_run webhook events.
# Receives the raw GitHub event JSON, applies deterministic gate checks,
# and creates a Hermes kanban task if a rubocop fix is needed.
#
# The kanban worker handles everything else: git checkout, rubocop scoping,
# fixing, committing, pushing.
#
# Exit codes:
#   0 — Task created (task info on stdout)
#   1 — Skipped (reason on stderr)
#   2 — Error (details on stderr)
#
# Usage:
#   ruby rubocop-preflight.rb '<raw GitHub event JSON>'
#   echo '<raw JSON>' | ruby rubocop-preflight.rb

require "json"
require "open3"
require "fileutils"

LOG_DIR = File.expand_path("~/webhook-logs")
LOG_FILE = File.join(LOG_DIR, "rubocop-preflight.log")

# --- Helpers ---

def log(level, msg)
  FileUtils.mkdir_p(LOG_DIR)
  timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  File.open(LOG_FILE, "a") { |f| f.puts("#{timestamp} [#{level.upcase}] #{msg}") }
end

def skip!(reason)
  log("skip", reason)
  $stderr.puts reason
  exit 1
end

def error!(reason)
  log("error", reason)
  $stderr.puts "ERROR: #{reason}"
  exit 2
end

def run(cmd)
  stdout, stderr, status = Open3.capture3(cmd)
  [stdout.strip, stderr.strip, status]
end

# --- Repo Path Mapping ---

REPO_MAP = {
  "scientist-hq/rx" => File.expand_path("~/src/rx/rx"),
  "scientist-hq/test" => File.expand_path("~/src/test"),
  "scientist-hq/benchmate" => File.expand_path("~/src/benchmate")
}.freeze

PROTECTED_BRANCHES = %w[main master develop staging production].freeze

# --- Parse raw event ---

raw_input = ARGV[0] || $stdin.read
error!("No input provided") if raw_input.nil? || raw_input.strip.empty?

begin
  event = JSON.parse(raw_input)
rescue JSON::ParserError => e
  error!("Failed to parse event JSON: #{e.message}")
end

# --- Gate 1: Is this a check_run event with a rubocop failure? ---

check_run = event["check_run"]
skip!("Not a check_run event") unless check_run

conclusion = check_run["conclusion"]
skip!("Not a failure (conclusion=#{conclusion})") unless conclusion == "failure"

check_name = check_run["name"] || ""
skip!("Not a rubocop check (name=#{check_name})") unless check_name.match?(/rubocop|lint|analysis/i)

# --- Gate 2: Protected branch? ---

branch = check_run.dig("check_suite", "head_branch") || check_run["head_branch"]
skip!("Could not determine branch from event") unless branch
skip!("Protected branch: #{branch}") if PROTECTED_BRANCHES.include?(branch)

# --- Gate 3: PR is draft or has no-auto-fix label? ---

repo_full_name = event.dig("repository", "full_name")
error!("No repository.full_name in event") unless repo_full_name

pr_json, _, pr_status = run(
  "gh pr list --repo #{repo_full_name} --head #{branch} " \
  "--json number,isDraft,labels --jq '.[0]'"
)

if pr_status.success? && !pr_json.empty? && pr_json != "null"
  pr_data = JSON.parse(pr_json)
  skip!("PR ##{pr_data['number']} is a draft") if pr_data["isDraft"]

  labels = (pr_data["labels"] || []).map { |l| l["name"] }
  skip!("PR ##{pr_data['number']} has no-auto-fix label") if labels.include?("no-auto-fix")
end

# --- Resolve repo path ---

repo_path = REPO_MAP[repo_full_name]
error!("Unknown repository: #{repo_full_name}") unless repo_path
error!("Repo path does not exist: #{repo_path}") unless Dir.exist?(repo_path)

# --- Create kanban task ---

head_sha = check_run["head_sha"] || "unknown"
pr_number = pr_data&.dig("number")
pr_label = pr_number ? "##{pr_number}" : branch
repo_short = repo_full_name.split("/").last

task_title = "Fix rubocop: #{repo_short} #{pr_label} (#{branch})"
idempotency_key = "rubocop-fix-#{repo_full_name}-#{branch}-#{head_sha[0..11]}"

task_body = JSON.generate({
  repo_full_name: repo_full_name,
  repo_path: repo_path,
  branch: branch,
  head_sha: head_sha,
  pr_number: pr_number,
  check_name: check_name,
  details_url: check_run["details_url"]
})

kanban_cmd = [
  "hermes", "kanban", "create",
  task_title,
  "--assignee", "default",
  "--body", task_body,
  "--skill", "fix-rubocop",
  "--workspace", "dir:#{repo_path}",
  "--idempotency-key", idempotency_key,
  "--max-runtime", "30m",
  "--created-by", "rubocop-preflight",
  "--json"
]

stdout, stderr, status = Open3.capture3(*kanban_cmd)

unless status.success?
  error!("Failed to create kanban task: #{stderr}\n#{stdout}")
end

log("info", "Created kanban task for #{task_title} (key: #{idempotency_key})")

puts stdout
