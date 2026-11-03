/*
  The hooks of the page furniture Metronic's layout script runs: the image field, the sticky block, the scroll spy
  and the context menu.
*/

const ImageInput = {
  mounted() {
    this.file = this.el.querySelector("[data-file]")
    this.frame = this.el.querySelector("[data-frame]")
    this.flag = this.el.querySelector("[data-remove-flag]")
    this.onChange = () => this.choose()
    this.onRemove = (event) => event.target.closest("[data-remove]") && this.remove()
    this.file.addEventListener("change", this.onChange)
    this.el.addEventListener("click", this.onRemove)
  },

  destroyed() {
    this.file?.removeEventListener("change", this.onChange)
    this.el.removeEventListener("click", this.onRemove)
  },

  initial() {
    return this.el.dataset.initial || ""
  },

  paint(url) {
    this.frame.style.backgroundImage = url ? `url('${url}')` : ""
    this.el.dataset.state = url ? "filled" : "empty"
  },

  choose() {
    const chosen = this.file.files?.[0]
    const reader = chosen && new FileReader()
    reader && ((reader.onload = () => {
      this.flag.value = ""
      this.paint(reader.result)
    }), reader.readAsDataURL(chosen))
  },

  remove() {
    const picked = this.file.files?.length > 0
    this.file.value = ""
    picked
      ? (this.flag.value = "", this.paint(this.initial()))
      : (this.flag.value = "1", this.paint(""))
  },
}

const Sticky = {
  mounted() {
    this.offset = Number(this.el.dataset.offset || 0)
    this.classes = (this.el.dataset.stuckClass || "").split(/\s+/).filter(Boolean)
    this.stuck = false
    this.onScroll = () => this.check()
    window.addEventListener("scroll", this.onScroll, {passive: true})
    this.check()
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
  },

  check() {
    const stuck = window.scrollY > this.offset
    stuck !== this.stuck && (this.stuck = stuck, this.paint())
  },

  paint() {
    this.stuck ? this.el.classList.add(...this.classes) : this.el.classList.remove(...this.classes)
    this.stuck ? (this.el.dataset.stuck = "") : delete this.el.dataset.stuck
  },
}

const Scrollspy = {
  mounted() {
    this.links = [...this.el.querySelectorAll("[data-spy-link]")]
    this.offset = Number(this.el.dataset.offset || 120)
    this.onScroll = () => this.update()
    this.onClick = (event) => this.go(event)
    window.addEventListener("scroll", this.onScroll, {passive: true})
    this.el.addEventListener("click", this.onClick)
    this.update()
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
    this.el.removeEventListener("click", this.onClick)
  },

  section(link) {
    const id = (link.getAttribute("href") || "").replace(/^#/, "")
    return id ? document.getElementById(id) : null
  },

  update() {
    const bottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
    const passed = this.links.filter((link) => {
      const section = this.section(link)
      return section && section.getBoundingClientRect().top <= this.offset
    })
    const current = bottom ? this.links.filter((link) => this.section(link)).at(-1) : passed.at(-1) || this.links[0]
    this.links.forEach((link) => link.setAttribute("aria-current", link === current ? "true" : "false"))
  },

  go(event) {
    const link = event.target.closest("[data-spy-link]")
    const section = link && this.section(link)
    section && (event.preventDefault(), window.scrollTo({top: window.scrollY + section.getBoundingClientRect().top - this.offset + 1, behavior: "smooth"}))
  },
}

const ContextMenu = {
  mounted() {
    this.menu = this.el.querySelector("[data-menu]")
    this.onContext = (event) => this.open(event)
    this.onDown = (event) => this.menu.hidden || this.menu.contains(event.target) || this.close()
    this.onKey = (event) => this.key(event)
    this.onClick = (event) => event.target.closest("[role=menuitem]") && this.close()
    this.el.addEventListener("contextmenu", this.onContext)
    document.addEventListener("pointerdown", this.onDown)
    document.addEventListener("keydown", this.onKey)
    window.addEventListener("scroll", this.onDown, {passive: true})
    this.menu.addEventListener("click", this.onClick)
  },

  destroyed() {
    this.el.removeEventListener("contextmenu", this.onContext)
    document.removeEventListener("pointerdown", this.onDown)
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("scroll", this.onDown)
  },

  items() {
    return [...this.menu.querySelectorAll("[role=menuitem]:not(:disabled)")]
  },

  open(event) {
    event.preventDefault()
    this.menu.hidden = false
    const box = this.menu.getBoundingClientRect()
    const left = Math.min(event.clientX, window.innerWidth - box.width - 8)
    const top = Math.min(event.clientY, window.innerHeight - box.height - 8)
    this.menu.style.left = `${Math.max(8, left)}px`
    this.menu.style.top = `${Math.max(8, top)}px`
    this.items()[0]?.focus()
  },

  close() {
    this.menu.hidden = true
  },

  key(event) {
    const open = !this.menu.hidden
    const items = this.items()
    const at = items.indexOf(document.activeElement)
    const move = {ArrowDown: at + 1, ArrowUp: at - 1, Home: 0, End: items.length - 1}[event.key]
    open && event.key === "Escape" && this.close()
    open && move !== undefined && (event.preventDefault(), items[(move + items.length) % items.length]?.focus())
  },
}

export default {
  "LineaUI.ImageInput": ImageInput,
  "LineaUI.Sticky": Sticky,
  "LineaUI.Scrollspy": Scrollspy,
  "LineaUI.ContextMenu": ContextMenu,
}
