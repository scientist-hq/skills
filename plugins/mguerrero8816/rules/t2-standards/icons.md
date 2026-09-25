# Icons — Lucide Only

## Never Add a Font Awesome Icon

Both Lucide and Font Awesome load in the app, so a new Font Awesome icon still renders. Use Lucide for every new icon. Never write a `fa-` class, an `<i class="fas ...">` tag, or `fa_icon` in new code. Do not convert existing Font Awesome icons that are not part of the change.

## Ruby Views

Use the `lucide_icon` helper with the kebab-case name and a size class. In a ViewComponent template, call `helpers.lucide_icon`.

- ❌ BAD: `%i.fas.fa-plus`
- ✅ GOOD: `= lucide_icon("plus", class: "icon-sm me-2")`

## React

Import the PascalCase component from `lucide-react`. Set its size with the `size` prop.

- ✅ GOOD: `import { Save } from 'lucide-react'`, then `<Save size={16} />`

## Size and Color

A Lucide SVG is 24px and ignores `font-size`. Give each Ruby view icon a size class from `app/assets/stylesheets/global/_icon-sizes.scss`: `icon-2xs` to `icon-5x`, `icon-fw`, and `icon-spin`. Do not use `fa-sm` or `fa-lg` on a Lucide icon. The stroke is `currentColor`, so a Bootstrap text class sets the color.

## Check the Name

Find the name on https://lucide.dev/icons before you use it. An unknown name raises `ArgumentError: Unknown icon <name>` and breaks the page.
