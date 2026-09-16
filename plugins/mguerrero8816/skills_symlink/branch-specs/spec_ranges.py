"""Print `path:start-end  <example line>` for every spec example the branch adds.

Reads the base branch off the PR, or takes it as the first argument. Run from `rx/`.
"""
import json
import re
import subprocess
import sys

PATHSPECS = ['spec', 'test/javascript', ':(glob)app/javascript/**/*.test.*', ':(glob)app/javascript/**/*.spec.*']
EXAMPLE = re.compile(r"^[ \t]*(it|specify|scenario|it_behaves_like|test)(\.[a-z]+)?[ \t]*[\s(\"'`]")
CLOSER = re.compile(r'^[ \t]*(end\b|\}\))')


def base_branch():
    if len(sys.argv) > 1:
        return sys.argv[1]
    pr = subprocess.run(['gh', 'pr', 'view', '--json', 'baseRefName'], capture_output=True, text=True)
    if pr.returncode == 0:
        return json.loads(pr.stdout)['baseRefName']
    return 'main'


def added_examples(base):
    """Walk the diff and keep every added example line with its line number in the new file."""
    diff = subprocess.run(['git', 'diff', f'{base}...HEAD', '--'] + PATHSPECS, capture_output=True, text=True)
    found = []
    path, lineno = None, 0
    for line in diff.stdout.splitlines():
        if line.startswith('+++ b/'):
            path, lineno = line[6:], 0
        elif hunk := re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)', line):
            lineno = int(hunk.group(1))
        elif line.startswith('-') or line.startswith('\\'):
            continue
        else:
            if line.startswith('+') and EXAMPLE.match(line[1:]):
                found.append((path, lineno, line[1:].strip()))
            lineno += 1
    return found


def end_line(lines, start):
    """The first closer at or left of the example's own indentation."""
    indent = len(lines[start - 1]) - len(lines[start - 1].lstrip())
    for i in range(start, len(lines)):
        text = lines[i]
        if not text.strip() or len(text) - len(text.lstrip()) > indent:
            continue
        if CLOSER.match(text):
            return i + 1
    return start


files = {}
for path, start, text in added_examples(base_branch()):
    local = path.removeprefix('rx/')
    if local not in files:
        files[local] = open(local).read().splitlines()
    print(f'{local}:{start}-{end_line(files[local], start)}  {text}')
