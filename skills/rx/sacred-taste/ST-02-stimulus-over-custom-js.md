# ST-02: Stimulus Over Custom JavaScript

**Level:** SHOULD follow
**Category:** Frontend

## Preference

For all new JavaScript, use Stimulus controllers in `app/javascript/controllers/`. Never add to legacy JS files.

## RX Pattern

```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['field', 'tooltip'];

  connect() {
    // initialization on DOM attach
  }

  updateField(event) {
    // action handler
    this.fieldTarget.value = event.target.value;
  }
}
```

## HTML Wiring

```haml
%div{ data: { controller: "example" } }
  %input{ data: { "example-target": "field", action: "change->example#updateField" } }
```

## Key Conventions

- `static targets = [...]` for DOM element references
- `this.fieldTarget` / `this.hasFieldTarget` for target access
- `connect()` / `disconnect()` lifecycle hooks
- Actions via `data-action="event->controller#method"`
