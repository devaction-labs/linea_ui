# phone_input in the showcase

1. Copy the examples next to the others:

       cp showcase_patch/examples/phone_input_*.html.heex \
          ~/ElixirProjects/linea_showcase/lib/linea_showcase_web/examples/

   They are picked up by file name (`<component>_<nn>.html.heex`, the component key is `phone_input`), so
   no registration is needed for the examples themselves. `Examples` recompiles when files are added.

2. List the component in the catalog, `lib/linea_showcase_web/catalog.ex`: add `phone_input` to the `forms`
   category, after `select` (the list order is the sidebar order), and to `@new_components`:

       forms:
         ~w(form input input_group checkbox radio segmented switch range textarea select phone_input tags_input ...)a,

       @new_components ~w(command_palette segmented ... timer phone_input)a

   `LineaUI.Docs.components()` already returns `phone_input` (it is in `LineaUI.components()`), so the doc page,
   its moduledoc and the attr table appear without more code.

3. The showcase must compile against this worktree's `linea_ui` (the component, `LineaUI.Components.PhoneInput.Format`
   and the `LineaUI.PhoneInput` hook in `assets/js/linea_ui/index.js`), and its CSS must be rebuilt
   (`mix assets.build`): the hook draws the list rows with utility classes that live in
   `assets/js/linea_ui/hooks/phone_input.js`, which `linea_ui.css` already scans (`@source "../js"`).

4. Example 05 sends `demo:country` (the `on_country_change` event); the showcase answers unknown events with a
   toast, so the reader sees `%{"id" => ..., "country" => "JM", "code" => "1"}`. No handler is needed.
   Example 06 calls `LineaUI.Components.PhoneInput.Format.e164/2` straight in the template.

5. The form examples use field names prefixed with the example (`pi1_phone`...), like the other forms
   examples, because `@form` is shared by the whole page and `demo:validate` merges params.
