const COPIED_MS = 2000

const textOf = (el) => (el ? ("value" in el && typeof el.value === "string" ? el.value : el.innerText) : "")

const toast = (message, color) =>
  message && window.dispatchEvent(new CustomEvent("linea:toast", {detail: {message, color}}))

/**
 * `Clipboard`: copies `data-value`, or the value (a field) or the text (anything else) of the element
 * `data-from` points at. On success it shows the `data-toast` notification (success color) and keeps
 * `data-copied` on the button for two seconds; on failure it shows `data-error-toast`. `data-on-copy` runs
 * after a copy.
 */
export default {
  "LineaUI.Clipboard": {
    mounted() {
      this.onClick = () => this.copy()
      this.el.addEventListener("click", this.onClick)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      clearTimeout(this.timer)
    },

    source() {
      const {value, from} = this.el.dataset
      return value ?? textOf(from && document.querySelector(from))
    },

    async copy() {
      const done = await navigator.clipboard?.writeText(this.source()).then(() => true, () => false)
      ;(done ? () => this.copied() : () => toast(this.el.dataset.errorToast, "error"))()
    },

    copied() {
      toast(this.el.dataset.toast, "success")
      this.el.toggleAttribute("data-copied", true)
      clearTimeout(this.timer)
      this.timer = setTimeout(() => this.el.removeAttribute("data-copied"), COPIED_MS)
      const onCopy = this.el.dataset.onCopy
      onCopy && onCopy !== "[]" && this.liveSocket.execJS(this.el, onCopy)
    },
  },
}
