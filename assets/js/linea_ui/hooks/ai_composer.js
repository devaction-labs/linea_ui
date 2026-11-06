/**
 * `LineaUI.AiComposer` (`ai_composer`): Enter sends the form, Shift+Enter breaks the line. An empty text, an
 * input method composing a character, or an answer still coming (`data-streaming` on the form) does not send.
 */
export default {
  "LineaUI.AiComposer": {
    mounted() {
      this.onKeydown = (event) => {
        if (event.key !== "Enter" || event.shiftKey || event.isComposing) return
        event.preventDefault()
        const form = this.el.form
        this.el.value.trim() !== "" && form && form.dataset.streaming === undefined && form.requestSubmit()
      }
      this.el.addEventListener("keydown", this.onKeydown)
    },

    destroyed() {
      this.el.removeEventListener("keydown", this.onKeydown)
    },
  },
}
