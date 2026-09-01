# Icons — Lucide Only

Lucide replaced Font Awesome in this app. Both libraries are still loaded, so a Font Awesome
icon still renders and can pass review by accident. Do not add one.

## Never Add a Font Awesome Icon

- **NEVER** write a `fa-` class, an `<i class="fas ...">` tag, or a `fa_icon` helper call in new code
- **ALWAYS** use Lucide for every new icon, in Ruby views and in React
- Existing `fa-` markup stays until someone converts it — do not convert unrelated icons in a change

## Ruby Views — the `lucide_icon` Helper

The `lucide-rails` gem supplies `lucide_icon`. Pass the kebab-case Lucide name and a size class.

**Examples:**
- ❌ BAD: `%i.fas.fa-plus`
- ✅ GOOD: `= lucide_icon("plus", class: "icon-sm me-2")`
- ✅ GOOD (inside a ViewComponent template): `= helpers.lucide_icon("loader-circle", class: "icon-sm icon-spin")`

## React — Import From `lucide-react`

Import the named component from `lucide-react`. The name is PascalCase.

**Examples:**
- ❌ BAD: `<i className="fas fa-save" />`
- ✅ GOOD: `import { Save } from 'lucide-react'`, then `<Save size={16} />`

## Sizing and Color

A Lucide SVG renders at 24px and ignores `font-size`, so a Ruby view icon needs an explicit size
class from `app/assets/stylesheets/global/_icon-sizes.scss`. The classes mirror the Font Awesome
names: `icon-2xs`, `icon-xs`, `icon-sm`, `icon-lg`, `icon-xl`, `icon-2xl`, `icon-3x`, `icon-4x`,
`icon-5x`, plus `icon-fw` to align icons in a list and `icon-spin` for a spinner. Size a React
icon with the `size` prop. Do not carry a `fa-sm` or `fa-lg` class over to a Lucide icon.

The stroke is `currentColor`, so a Bootstrap text class colors the icon.

- ✅ GOOD: `= lucide_icon("circle-check", class: "icon-sm text-success")`

## Finding the Right Name

Lucide does not carry every Font Awesome name. Search https://lucide.dev/icons for the closest
match before you guess. An unknown name raises `ArgumentError: Unknown icon <name>` at render
time, so a wrong guess breaks the page.
