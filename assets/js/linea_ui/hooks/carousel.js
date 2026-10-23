import {
  fraction,
  keyStep,
  nearest,
  parallax,
  placement,
  progress,
  resolveIndex,
  scrollFor,
  swipe,
  target,
  thumb,
} from "../lib/carousel_logic.js"

const STACKED = ["fade", "flip", "cube", "cards", "coverflow", "creative"]

/**
 * Runs a component's event attr: a `%JS{}` (rendered as JSON) is executed, an event name is pushed with
 * `payload` to the element's `phx-target`, or to its LiveView.
 */
const emit = (hook, spec, payload, source = hook.el) => {
  const run = {
    js: () => hook.liveSocket.execJS(source, spec),
    push: () => hook.pushEventTo(hook.el.getAttribute("phx-target") || hook.el, spec, payload),
  }
  spec && run[spec.trim().startsWith("[") ? "js" : "push"]()
}

const listen = (hook, element, type, handler, options) => {
  element.addEventListener(type, handler, options)
  hook.cleanups.push(() => element.removeEventListener(type, handler, options))
}

const Carousel = {
  mounted() {
    this.cleanups = []
    this.lastServer = this.serverIndex()
    this.index = this.lastServer
    listen(this, this.el, "scroll", (event) => event.target === this.track() && this.scrolled(), {capture: true, passive: true})
    listen(this, this.el, "click", (event) => this.clicked(event))
    listen(this, this.el, "keydown", (event) => this.keyed(event))
    listen(this, this.el, "pointerdown", (event) => this.pressed(event))
    listen(this, this.el, "dblclick", (event) => this.zoom(event))
    listen(this, this.el, "pointerenter", () => this.pause())
    listen(this, this.el, "pointerleave", () => this.play())
    listen(this, this.el, "focusin", () => this.pause())
    listen(this, this.el, "focusout", () => this.play())
    this.handleEvent("linea:carousel", ({id, index}) => id === this.el.id && this.go(Number(index)))
    this.render()
    this.jump(this.index)
    this.play()
  },

  updated() {
    const server = this.serverIndex()
    const index = resolveIndex({current: this.index, lastServer: this.lastServer, server, count: this.slides().length})
    const moved = server !== this.lastServer
    this.lastServer = server
    this.index = index
    moved ? this.jump(index) : this.render()
    this.play()
  },

  destroyed() {
    this.pause()
    this.stopDrag?.()
    cancelAnimationFrame(this.frame)
    this.cleanups.forEach((cleanup) => cleanup())
  },

  serverIndex() {
    return Number(this.el.dataset.serverIndex || 0)
  },

  track() {
    return this.el.querySelector(":scope > [data-carousel-track]")
  },

  effect() {
    return this.el.dataset.effect || "slide"
  },

  stacked() {
    return STACKED.includes(this.effect())
  },

  vertical() {
    return this.el.dataset.direction === "vertical"
  },

  direction() {
    return this.vertical() ? "vertical" : "horizontal"
  },

  loop() {
    return this.el.dataset.loop === "true"
  },

  slides() {
    return [...this.track().querySelectorAll(":scope > [data-carousel-slide]")]
  },

  starts() {
    return this.slides().map((slide) => (this.vertical() ? slide.offsetTop : slide.offsetLeft))
  },

  position() {
    const track = this.track()
    return this.vertical() ? track.scrollTop : track.scrollLeft
  },

  sizes() {
    const track = this.track()
    return this.vertical()
      ? {scroll: track.scrollHeight, client: track.clientHeight}
      : {scroll: track.scrollWidth, client: track.clientWidth}
  },

  room() {
    const {scroll, client} = this.sizes()
    return scroll - client
  },

  step(delta, loop = this.loop()) {
    this.go(target(this.index + delta, this.slides().length, loop))
  },

  go(index, behavior = "smooth") {
    const next = target(index, this.slides().length, this.loop())
    this.resetZoom()
    this.stacked() ? this.select(next) : this.scrollTo(next, behavior)
  },

  jump(index) {
    this.go(index, "instant")
  },

  scrollTo(index, behavior) {
    const start = this.starts()[index] ?? 0
    this.track().scrollTo({[this.vertical() ? "top" : "left"]: Math.min(start, this.room()), behavior})
    this.select(index)
  },

  select(index) {
    const changed = index !== this.index
    this.index = index
    this.render()
    changed && emit(this, this.el.dataset.onChange, {id: this.el.id, index})
  },

  scrolled() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => {
      const position = this.position()
      const atEnd = this.room() > 0 && position >= this.room() - 1
      const index = atEnd ? this.slides().length - 1 : nearest(position, this.starts())
      this.dragging || index === this.index ? this.render() : this.select(index)
    })
  },

  clicked(event) {
    const control = event.target.closest("[data-carousel-prev], [data-carousel-next], [data-carousel-bullet]")
    const actions = {
      prev: () => this.step(-1),
      next: () => this.step(1),
      bullet: () => this.go(Number(control.dataset.carouselBullet)),
    }
    const name = control && ["prev", "next", "bullet"].find((key) => control.hasAttribute(`data-carousel-${key}`))
    name && actions[name]()
  },

  keyed(event) {
    const step = event.target.closest("input, textarea, select") ? null : keyStep(event.key, this.direction())
    const count = this.slides().length
    const actions = {first: () => this.go(0), last: () => this.go(count - 1)}
    step !== null && event.preventDefault()
    step !== null && (typeof step === "number" ? this.step(step) : actions[step]())
  },

  pressed(event) {
    const thumbEl = event.target.closest("[data-carousel-thumb]")
    const onTrack = event.target.closest("[data-carousel-track]") === this.track()
    thumbEl ? this.grabThumb(event, thumbEl) : onTrack && this.dragTrack(event)
  },

  drag(move, up) {
    const stop = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", finish)
      this.stopDrag = null
    }
    const finish = (event) => {
      stop()
      up(event)
    }
    this.stopDrag?.()
    this.stopDrag = stop
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", finish)
  },

  dragTrack(event) {
    const start = {x: event.clientX, y: event.clientY, position: this.position()}
    const mouse = !this.stacked() && event.pointerType === "mouse" && event.button === 0
    const move = (moved) => {
      const delta = this.vertical() ? moved.clientY - start.y : moved.clientX - start.x
      this.dragging = true
      this.track().dataset.dragging = ""
      this.track().scrollTo({[this.vertical() ? "top" : "left"]: start.position - delta, behavior: "instant"})
    }
    const up = (released) => {
      const step = swipe(released.clientX - start.x, released.clientY - start.y, this.direction())
      this.dragging = false
      delete this.track().dataset.dragging
      const settle = {
        mouse: () => this.go(step === 0 ? nearest(this.position(), this.starts()) : this.index + step),
        stacked: () => step !== 0 && this.step(step),
        none: () => null,
      }
      settle[mouse ? "mouse" : this.stacked() ? "stacked" : "none"]()
    }
    mouse && event.preventDefault()
    this.drag(mouse ? move : () => null, up)
  },

  grabThumb(event, handle) {
    const bar = handle.parentElement.getBoundingClientRect()
    const own = handle.getBoundingClientRect()
    const grab = this.vertical() ? event.clientY - own.top : event.clientX - own.left
    const length = this.vertical() ? bar.height : bar.width
    const {scroll, client} = this.sizes()
    const move = (moved) => {
      const at = (this.vertical() ? moved.clientY - bar.top : moved.clientX - bar.left) - grab
      this.track().dataset.dragging = ""
      this.track().scrollTo({[this.vertical() ? "top" : "left"]: scrollFor(at / length, scroll, client), behavior: "instant"})
    }
    const up = () => {
      delete this.track().dataset.dragging
      this.go(nearest(this.position(), this.starts()))
    }
    event.preventDefault()
    this.drag(move, up)
  },

  zoom(event) {
    const ratio = Number(this.el.dataset.zoom || 0)
    const slide = event.target.closest("[data-carousel-slide]")
    const content = ratio > 1 && slide?.firstElementChild
    content && this.toggleZoom(content, ratio, event)
  },

  toggleZoom(content, ratio, event) {
    const rect = content.getBoundingClientRect()
    const zoomed = content.dataset.zoomed === "true"
    content.style.transformOrigin = `${event.clientX - rect.left}px ${event.clientY - rect.top}px`
    content.style.transform = zoomed ? "" : `scale(${ratio})`
    content.dataset.zoomed = String(!zoomed)
  },

  resetZoom() {
    this.track()
      .querySelectorAll("[data-zoomed='true']")
      .forEach((content) => {
        content.style.transform = ""
        content.dataset.zoomed = "false"
      })
  },

  play() {
    const delay = Number(this.el.dataset.autoplay || 0)
    this.pause()
    delay > 0 && (this.timer = setInterval(() => this.step(1, true), delay))
  },

  pause() {
    clearInterval(this.timer)
  },

  render() {
    const slides = this.slides()
    const count = slides.length
    this.el.dataset.activeIndex = String(this.index)
    slides.forEach((slide, index) => this.place(slide, index, count))
    this.renderButtons(count)
    this.renderPagination(count)
    this.renderScrollbar(count)
    this.renderParallax(slides)
  },

  place(slide, index, count) {
    const {offset, distance, side, near} = placement(index, this.index)
    const active = index === this.index
    slide.setAttribute("role", "group")
    slide.setAttribute("aria-roledescription", "slide")
    slide.setAttribute("aria-label", fraction(index, count))
    slide.dataset.active = String(active)
    this.stacked() && slide.toggleAttribute("inert", !active)
    this.stacked() && slide.style.setProperty("--offset", offset)
    this.stacked() && slide.style.setProperty("--distance", distance)
    this.stacked() && slide.style.setProperty("--side", side)
    this.stacked() && slide.style.setProperty("--near", near)
    this.stacked() && (slide.style.zIndex = String(count - distance))
  },

  renderButtons(count) {
    const prev = this.el.querySelector(":scope > [data-carousel-prev]")
    const next = this.el.querySelector(":scope > [data-carousel-next]")
    prev && (prev.disabled = !this.loop() && this.index <= 0)
    next && (next.disabled = !this.loop() && this.index >= count - 1)
  },

  renderPagination(count) {
    const box = this.el.querySelector(":scope > [data-carousel-pagination]")
    const renderers = {
      bullets: () => this.renderBullets(box, count),
      fraction: () => (box.textContent = fraction(this.index, count)),
      progress: () => this.renderProgress(box, count),
    }
    box && renderers[box.dataset.carouselPagination]?.()
  },

  renderBullets(box, count) {
    const label = this.el.dataset.bulletLabel || "Go to slide"
    box.children.length === count ||
      box.replaceChildren(
        ...Array.from({length: count}, (_, index) => {
          const bullet = document.createElement("button")
          bullet.type = "button"
          bullet.className = "carousel-bullet"
          bullet.dataset.carouselBullet = String(index)
          bullet.setAttribute("aria-label", `${label} ${index + 1}`)
          return bullet
        }),
      )
    ;[...box.children].forEach((bullet, index) => {
      bullet.dataset.active = String(index === this.index)
      bullet.toggleAttribute("aria-current", index === this.index)
    })
  },

  renderProgress(box, count) {
    const fill = box.firstElementChild || box.appendChild(document.createElement("span"))
    const amount = progress(this.index, count)
    fill.className = "carousel-progress-fill"
    fill.style.transform = this.vertical() ? `scaleY(${amount})` : `scaleX(${amount})`
  },

  renderScrollbar(count) {
    const handle = this.el.querySelector(":scope > [data-carousel-scrollbar] [data-carousel-thumb]")
    const {scroll, client} = this.sizes()
    const total = Math.max(count, 1)
    const {size, start} = this.stacked() ? {size: 1 / total, start: this.index / total} : thumb(this.position(), scroll, client)
    const [lengthKey, startKey] = this.vertical() ? ["height", "top"] : ["width", "left"]
    handle && (handle.style[lengthKey] = `${size * 100}%`)
    handle && (handle.style[startKey] = `${start * 100}%`)
  },

  renderParallax(slides) {
    const room = this.room()
    const overall = room > 0 ? this.position() / room : 0
    const axis = this.vertical() ? "translateY" : "translateX"
    const {client} = this.sizes()
    const starts = this.starts()
    this.el.querySelectorAll(":scope > [data-carousel-parallax]").forEach((element) => {
      element.style.transform = `${axis}(${parallax(element.dataset.carouselParallax, overall)})`
    })
    slides.forEach((slide, index) => {
      const amount = client > 0 ? Math.min(Math.max((starts[index] - this.position()) / client, -1), 1) : 0
      slide.querySelectorAll("[data-carousel-parallax]").forEach((element) => {
        element.style.transform = `${axis}(${parallax(element.dataset.carouselParallax, -amount)})`
      })
    })
  },
}

export default {"LineaUI.Carousel": Carousel}
