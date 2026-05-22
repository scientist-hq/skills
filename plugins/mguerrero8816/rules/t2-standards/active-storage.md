# ActiveStorage

## No Silent File Replacement

- **NEVER purge and replace an attached file unless the user explicitly asks for replacement behaviour**
- If a file is already attached when an attach is attempted, log an error and skip — do not silently overwrite
- Guard against double-attachment at the earliest possible point (e.g. top of the method that orchestrates the operation)

**Examples:**
- ❌ BAD:
  ```ruby
  @document.file.purge if @document.file.attached?
  @document.file.attach(...)
  ```
- ✅ GOOD:
  ```ruby
  if @document.file.attached?
    Rails.logger.error("[MyClass] file already attached for document=#{@document.uuid} — skipping")
  else
    @document.file.attach(...)
  end
  ```
