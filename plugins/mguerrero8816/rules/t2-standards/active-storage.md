# ActiveStorage

## No Silent File Replacement

Never purge and replace an attached file unless the user asks for replacement. If a file is already attached, log an error and skip the attach. Put the guard at the top of the method that runs the operation.

```ruby
if @document.file.attached?
  Rails.logger.error("[MyClass] file already attached for document=#{@document.uuid} — skipping")
else
  @document.file.attach(...)
end
```
