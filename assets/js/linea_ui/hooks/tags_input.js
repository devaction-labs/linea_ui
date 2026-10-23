/**
 * `<.tags_input>` renders the same listbox as `<.select>` in its `tags` mode (`data-mode="tags"`), so it is
 * driven by the same hook; this name is kept for apps that mount it by hand.
 */
import {Listbox} from "./select.js"

export default {"LineaUI.TagsInput": Listbox}
