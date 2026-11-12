import {splitTokens, tokenSpacing} from "../lib/token_mirror.js"

/**
 * `LineaUI.TextareaTokens`: keeps the mirror of a textarea with `tokens` equal to its text. The hook
 * sits on the wrapper `.linea-tokens`: the `<textarea>` has transparent text and the
 * `[data-token-mirror]` box draws the same text over it, with the `{{tokens}}` styled. On every input the
 * mirror is rebuilt from the textarea's value (text nodes only, nothing is read as HTML), its scroll
 * follows the textarea and the width of each token is matched to what the textarea gives those characters.
 */
const draw = (mirror, text) => {
  const nodes = splitTokens(text).map(({kind, text}) => {
    if (kind === "text") return document.createTextNode(text)
    const code = document.createElement("code")
    code.className = "linea-token"
    code.textContent = text
    return code
  })
  mirror.replaceChildren(...nodes, document.createTextNode("​"))
}

const fit = (mirror) => {
  const tokens = [...mirror.querySelectorAll(".linea-token")]
  if (tokens.length === 0) return
  const probe = document.createElement("span")
  probe.style.cssText = "position:absolute;visibility:hidden;white-space:pre;letter-spacing:normal"
  mirror.appendChild(probe)
  tokens.forEach((token) => (token.style.letterSpacing = "0px"))
  const own = tokens.map((token) => token.getBoundingClientRect().width)
  const spacing = tokens.map((token, index) => {
    probe.textContent = token.textContent
    return tokenSpacing(own[index], probe.getBoundingClientRect().width, token.textContent.length)
  })
  tokens.forEach((token, index) => (token.style.letterSpacing = `${spacing[index]}px`))
  probe.remove()
}

const follow = (area, mirror) => {
  const style = getComputedStyle(area)
  const bar = area.offsetWidth - area.clientWidth - (parseFloat(style.borderLeftWidth) || 0) - (parseFloat(style.borderRightWidth) || 0)
  mirror.style.right = `${Math.max(0, bar)}px`
  mirror.scrollTop = area.scrollTop
}

export default {
  "LineaUI.TextareaTokens": {
    mounted() {
      this.area = this.el.querySelector("textarea")
      this.mirror = this.el.querySelector("[data-token-mirror]")
      if (!this.area || !this.mirror) return

      this.onInput = () => this.render()
      this.onScroll = () => follow(this.area, this.mirror)
      this.area.addEventListener("input", this.onInput)
      this.area.addEventListener("scroll", this.onScroll)
      this.observer = typeof ResizeObserver === "function" ? new ResizeObserver(() => this.render()) : null
      this.observer?.observe(this.area)
      document.fonts?.ready?.then(() => this.el.isConnected && this.render())
      this.render()
    },

    updated() {
      this.area = this.el.querySelector("textarea")
      this.mirror = this.el.querySelector("[data-token-mirror]")
      this.area && this.mirror && this.render()
    },

    destroyed() {
      this.area?.removeEventListener("input", this.onInput)
      this.area?.removeEventListener("scroll", this.onScroll)
      this.observer?.disconnect()
    },

    render() {
      draw(this.mirror, this.area.value)
      fit(this.mirror)
      follow(this.area, this.mirror)
    },
  },
}
