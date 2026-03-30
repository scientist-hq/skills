# SR-08: ActiveStorage Only

**Level:** MUST follow
**Category:** Architecture

## Rule

All new file upload functionality must use ActiveStorage. Never use Paperclip for new code.

## Why

Paperclip is deprecated and unmaintained. RX is migrating existing Paperclip attachments to ActiveStorage. New Paperclip usage creates more migration debt.

## Correct

```ruby
# GOOD: ActiveStorage
class Document < ApplicationRecord
  has_one_attached :file
  has_many_attached :images
end

# Usage
document.file.attach(io: File.open('path'), filename: 'doc.pdf')
document.file.attached?  # true
url_for(document.file)   # generates URL
```

## Incorrect

```ruby
# BAD: Paperclip (deprecated)
class Document < ApplicationRecord
  has_attached_file :file
  validates_attachment_content_type :file, content_type: /\Aapplication\/pdf\z/
end
```

## Legacy Paperclip

Existing Paperclip attachments exist throughout the codebase. Don't touch them unless migrating them to ActiveStorage as a dedicated task.
