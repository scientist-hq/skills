# Styling Preferences

## Build a Design From the App's Existing CSS

Match a mockup with the app's existing styles. Do not copy the mockup's stylesheet. The design is the layout, the grouping, and the wording.

1. Use a Bootstrap 5.3 utility first.
2. If no utility fits, use an existing class from the app's SCSS. Look for a page that already has the same shape.
3. Add new CSS only when neither one does the job. Keep the block small and put it in the view's own SCSS partial. Tell Mike what you added and why.

Never copy a mockup's colors, sizes, or spacing as literal values.

- ❌ BAD: `padding: 0.5rem 0.75rem; font-size: 0.875rem;`
- ✅ GOOD: `p-2 small`
- ✅ GOOD: `table.table.table-sm` with `text-uppercase small text-muted fw-semibold` on the label cells, plus one small block for a sticky column
