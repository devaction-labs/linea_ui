/**
 * The drop panel of `<.upload>`: LiveView does the upload (`phx-drop-target`, `live_file_input`); this hook only
 * marks the panel while files are dragged over it and opens the file chooser from the keyboard.
 */
import {depthAfter, isOver} from "../lib/dropzone_logic.js"

const DRAG_EVENTS = ["dragenter", "dragleave", "drop"]

const Upload = {
  mounted() {
    this.depth = 0
    this.onDrag = (event) => {
      this.depth = depthAfter(this.depth, event.type)
      this.el.toggleAttribute("data-dragging", isOver(this.depth))
    }
    this.onKey = (event) => {
      const browse = event.target.closest("[data-browse]")
      const input = this.el.querySelector("input[type=file]")
      browse && ["Enter", " "].includes(event.key) && input && (event.preventDefault(), input.click())
    }
    DRAG_EVENTS.forEach((type) => this.el.addEventListener(type, this.onDrag))
    this.el.addEventListener("keydown", this.onKey)
  },

  updated() {
    this.el.toggleAttribute("data-dragging", isOver(this.depth))
  },
}

export default {"LineaUI.Upload": Upload}
