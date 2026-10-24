import {execWithPayload} from "../lib/js_payload.js"
/**
 * The application shell: the sidebar state (LineOne's `is-sidebar-open`), the collapsible groups of the sidebar
 * panel, the poppers of the header and the sidebar, the main sidebar tooltips and the right sidebar drawer.
 *
 * State the server renders (`data-open`) wins when it changes; a choice made in the browser survives patches that
 * did not change it, and live navigation (the choice is remembered per shell id for the life of the page).
 */
import {RAIL_KEY, breakpointName, clockText, initialCollapsed, initialOpen, isMobile, place, railValue, smAndUp, storedValue, tipSpot} from "../lib/shell_logic.js"

const SIDEBAR_KEY = "linea-sidebar"
const OPEN_CLASS = "is-sidebar-open"
const RESIZE_DELAY = 175
const COMMANDS = ["open", "close", "toggle"]

const memory = new Map()

const read = (key) => {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

const write = (key, value) => {
  try {
    localStorage.setItem(key, value)
  } catch {}
}

const setVh = () => document.documentElement.style.setProperty("--vh", `${window.innerHeight * 0.01}px`)

const screen = () => ({width: window.innerWidth, height: window.innerHeight})

const serverOpen = (el) => el.dataset.open === "true"

const execAttr = (hook, el, name) => {
  const js = el.getAttribute(name)
  execWithPayload(hook.liveSocket, el, js, {id: el.id})
}

const notify = (hook, kind, payload) => {
  const event = hook.el.getAttribute(`data-${kind}-event`)
  event && hook.pushEventTo(hook.el.dataset.target || hook.el, event, payload)
  execAttr(hook, hook.el, `data-on-${kind}`)
}

const listenCommands = (hook, actions) => {
  hook.commandListeners = COMMANDS.map((name) => {
    const local = (event) => event.target === hook.el && actions[name]()
    hook.el.addEventListener(`linea:${name}`, local)
    hook.handleEvent(`linea:${name}`, ({id}) => typeof id === "string" && hook.el.matches(id) && actions[name]())
    return () => hook.el.removeEventListener(`linea:${name}`, local)
  })
}

const stopCommands = (hook) => (hook.commandListeners ?? []).forEach((stop) => stop())

const fixedAt = (box, anchor, placement, gap) => {
  box.style.position = "fixed"
  box.style.top = "0px"
  box.style.left = "0px"
  const origin = box.getBoundingClientRect()
  const spot = place({
    placement,
    gap,
    anchor: anchor.getBoundingClientRect(),
    box: {width: origin.width, height: origin.height},
    origin: {top: origin.top, left: origin.left},
    screen: screen(),
  })
  box.style.top = `${spot.top}px`
  box.style.left = `${spot.left}px`
}

const settle = (el) => {
  el.setAttribute("data-settling", "")
  requestAnimationFrame(() => requestAnimationFrame(() => el.removeAttribute("data-settling")))
}

const AppShell = {
  mounted() {
    this.server = serverOpen(this.el)
    this.breakpoint = breakpointName(window.innerWidth)
    const open = initialOpen({width: window.innerWidth, stored: this.stored(), rendered: this.server})
    settle(this.el)
    this.apply(open)
    this.remember()
    open !== this.server && notify(this, "toggle", {id: this.el.id, open})
    setVh()

    this.onClick = (event) => {
      const toggle = event.target.closest("[data-sidebar-toggle]")
      const close = event.target.closest("[data-sidebar-close]")
      toggle && this.choose(!this.isOpen())
      close && this.isOpen() && this.choose(false)
    }
    this.el.addEventListener("click", this.onClick)

    listenCommands(this, {
      open: () => this.isOpen() || this.choose(true),
      close: () => this.isOpen() && this.choose(false),
      toggle: () => this.choose(!this.isOpen()),
    })

    this.onResize = () => {
      clearTimeout(this.resizeTimer)
      this.resizeTimer = setTimeout(() => this.resized(), RESIZE_DELAY)
    }
    window.addEventListener("resize", this.onResize, {passive: true})

    this.hidePreloader()
  },

  updated() {
    const server = serverOpen(this.el)
    const changed = server !== this.server
    this.server = server
    changed && this.apply(server)
    this.apply(this.isOpen())
    this.remember()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    window.removeEventListener("resize", this.onResize)
    clearTimeout(this.resizeTimer)
    clearTimeout(this.preloaderTimer)
    stopCommands(this)
  },

  stored() {
    const remembered = memory.get(this.el.id)
    const fresh = remembered && remembered.server === this.server
    return fresh ? storedValue(remembered.client) : this.el.dataset.persist === "true" ? read(SIDEBAR_KEY) : null
  },

  remember() {
    memory.set(this.el.id, {server: this.server, client: this.isOpen()})
  },

  isOpen() {
    return this.el.classList.contains(OPEN_CLASS)
  },

  apply(open) {
    this.el.classList.toggle(OPEN_CLASS, open)
    this.el
      .querySelectorAll("[data-sidebar-toggle]")
      .forEach((button) => button.setAttribute("aria-expanded", String(open)))
  },

  choose(open) {
    this.apply(open)
    this.el.dataset.persist === "true" && write(SIDEBAR_KEY, storedValue(open))
    this.remember()
    notify(this, "toggle", {id: this.el.id, open})
  },

  resized() {
    setVh()
    const name = breakpointName(window.innerWidth)
    const changed = name !== this.breakpoint
    this.breakpoint = name
    changed && this.isOpen() && (this.apply(false), this.remember(), notify(this, "toggle", {id: this.el.id, open: false}))
    changed && smAndUp(window.innerWidth) && this.hideMobileSearch()
  },

  hideMobileSearch() {
    this.el
      .querySelectorAll("[data-mobile-searchbar]")
      .forEach((bar) => getComputedStyle(bar).display !== "none" && execAttr(this, bar, "data-hide"))
  },

  hidePreloader() {
    const preloader = this.el.querySelector("[data-app-preloader]")
    preloader &&
      (this.preloaderTimer = setTimeout(() => {
        preloader.classList.add("is-leaving")
        preloader.addEventListener("animationend", () => preloader.classList.add("hidden"), {once: true})
      }, 300))
  },
}

const SidebarGroup = {
  mounted() {
    this.server = this.el.dataset.open
  },

  updated() {
    const server = this.el.dataset.open
    const changed = server !== this.server
    this.server = server
    changed && (this.el.open = server === "true")
  },
}

const ShellPopper = {
  mounted() {
    this.shown = false
    this.trigger = this.el.dataset.trigger ?? "click"

    this.onTrigger = (event) => {
      const fromRef = event.target.closest("[data-popper-ref]")
      fromRef && (this.trigger === "focus" ? this.show() : this.toggle())
    }
    this.el.addEventListener(this.trigger === "focus" ? "focusin" : "click", this.onTrigger)

    this.onClose = (event) => this.shown && event.target.closest("[data-popper-close]") && this.hide()
    this.el.addEventListener("click", this.onClose)

    this.onOutside = (event) => this.shown && !this.el.contains(event.target) && this.hide()
    document.addEventListener("click", this.onOutside)

    this.onKey = (event) => event.key === "Escape" && this.shown && (this.hide(), this.ref()?.focus())
    document.addEventListener("keydown", this.onKey)

    this.onMove = () => this.shown && this.position()
    window.addEventListener("resize", this.onMove, {passive: true})
    window.addEventListener("scroll", this.onMove, {passive: true, capture: true})
  },

  updated() {
    this.shown && (this.mark(true), this.position())
  },

  destroyed() {
    this.el.removeEventListener(this.trigger === "focus" ? "focusin" : "click", this.onTrigger)
    this.el.removeEventListener("click", this.onClose)
    document.removeEventListener("click", this.onOutside)
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("resize", this.onMove)
    window.removeEventListener("scroll", this.onMove, {capture: true})
  },

  ref() {
    return this.el.querySelector("[data-popper-ref]")
  },

  box() {
    return this.el.querySelector("[data-popper-box]")
  },

  position() {
    const ref = this.ref()
    const box = this.box()
    ref && box && fixedAt(box, ref, this.el.dataset.placement ?? "bottom-start", Number(this.el.dataset.gap ?? 12))
  },

  mark(on) {
    const ref = this.ref()
    const box = this.box()
    const list = (name) => (ref?.dataset[name] ?? "").split(" ").filter(Boolean)
    ref?.classList.remove(...list(on ? "closedClass" : "openClass"))
    ref?.classList.add(...list(on ? "openClass" : "closedClass"))
    ref?.classList.toggle("is-active", on)
    ref?.setAttribute("aria-expanded", String(on))
    box?.classList.toggle("show", on)
  },

  show() {
    this.shown = true
    this.mark(true)
    this.position()
  },

  hide() {
    this.shown = false
    this.mark(false)
  },

  toggle() {
    this.shown ? this.hide() : this.show()
  },
}

const tooltipOf = (event) => {
  const ref = event.target.closest?.("[data-tooltip-ref]")
  return {ref, tip: ref?.querySelector(":scope > [role=tooltip]")}
}

const ShellTooltips = {
  mounted() {
    this.onEnter = (event) => {
      const {ref, tip} = tooltipOf(event)
      tip && (fixedAt(tip, ref, "right", 10), tip.classList.add("show"))
    }
    this.onLeave = (event) => {
      const {ref, tip} = tooltipOf(event)
      const stays = ref && event.relatedTarget && ref.contains(event.relatedTarget)
      tip && !stays && tip.classList.remove("show")
    }
    this.el.addEventListener("mouseover", this.onEnter)
    this.el.addEventListener("focusin", this.onEnter)
    this.el.addEventListener("mouseout", this.onLeave)
    this.el.addEventListener("focusout", this.onLeave)
  },

  destroyed() {
    this.el.removeEventListener("mouseover", this.onEnter)
    this.el.removeEventListener("focusin", this.onEnter)
    this.el.removeEventListener("mouseout", this.onLeave)
    this.el.removeEventListener("focusout", this.onLeave)
  },
}

const leave = (node, done) => {
  node.classList.add("animate:leave")
  node.addEventListener(
    "animationend",
    () => {
      node.classList.remove("animate:leave")
      done()
    },
    {once: true},
  )
}

const RightSidebar = {
  mounted() {
    this.active = false
    this.server = serverOpen(this.el)

    listenCommands(this, {
      open: () => this.open(),
      close: () => this.close(),
      toggle: () => (this.active ? this.close() : this.open()),
    })

    this.onClick = (event) => {
      const closes = event.target.matches("[data-drawer-overlay]") || event.target.closest("[data-drawer-close]")
      closes && this.close()
    }
    this.el.addEventListener("click", this.onClick)

    this.onKey = (event) => event.key === "Escape" && this.active && this.close()
    document.addEventListener("keydown", this.onKey)

    this.server && this.open()
  },

  updated() {
    const server = serverOpen(this.el)
    const changed = server !== this.server
    this.server = server
    changed && (server ? this.open() : this.close())
    this.active && this.reveal()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    document.removeEventListener("keydown", this.onKey)
    stopCommands(this)
  },

  parts() {
    return {
      overlay: this.el.querySelector("[data-drawer-overlay]"),
      content: this.el.querySelector("[data-drawer-content]"),
    }
  },

  reveal() {
    const {overlay, content} = this.parts()
    overlay.classList.remove("hidden")
    content.classList.remove("hidden")
    content.setAttribute("aria-hidden", "false")
  },

  open() {
    this.active || this.show()
  },

  show() {
    this.active = true
    this.returnTo = document.activeElement
    this.reveal()
    this.parts().content.querySelector("[data-drawer-close]")?.focus({preventScroll: true})
    notify(this, "open", {id: this.el.id})
  },

  close() {
    this.active && this.hide()
  },

  hide() {
    this.active = false
    const {overlay, content} = this.parts()
    leave(overlay, () => this.active || overlay.classList.add("hidden"))
    leave(content, () => this.active || content.classList.add("hidden"))
    content.setAttribute("aria-hidden", "true")
    this.returnTo?.focus?.({preventScroll: true})
    notify(this, "close", {id: this.el.id})
  },
}

/**
 * The framed shell's menu (`framed_sidebar/1`): collapsed to a 60px rail of icons or open with its labels. The
 * state lives in `data-collapsed`, owned by the browser: the server's choice (`data-server-collapsed`) wins only
 * when it changes, and the person's last choice is kept in `localStorage["linea-rail"]` (`data-persist`). Any
 * element with `data-rail-toggle="<id of the menu>"` collapses and expands it, a module of the menu opens the
 * rail again when it is clicked, and below 768px the menu is a top bar whose hamburger (`data-mobile-toggle`)
 * sets `data-mobile-open`. `on_collapse` is pushed with `%{"id" => id, "collapsed" => boolean}`.
 */
const RAIL_TIP_GAP = 12

const pinTip = (item) => {
  const tip = item?.querySelector(":scope > .rail-tip")
  const spot = tip && tipSpot(item.getBoundingClientRect(), RAIL_TIP_GAP)
  spot && (tip.style.top = `${spot.top}px`, tip.style.left = `${spot.left}px`)
}

const ShellRail = {
  mounted() {
    this.server = this.el.dataset.serverCollapsed === "true"
    const collapsed = initialCollapsed({
      width: window.innerWidth,
      stored: this.el.dataset.persist === "true" ? read(RAIL_KEY) : null,
      rendered: this.server,
    })
    this.apply(collapsed)
    collapsed !== this.server && this.push(collapsed)

    this.onClick = (event) => this.click(event)
    this.onKey = (event) => event.key === "Escape" && this.el.dataset.mobileOpen === "true" && this.mobile(false)
    this.onResize = () => !isMobile(window.innerWidth) && this.mobile(false)
    this.onTip = (event) => this.collapsed() && pinTip(event.target.closest?.(".rail-item"))
    document.addEventListener("click", this.onClick)
    document.addEventListener("keydown", this.onKey)
    window.addEventListener("resize", this.onResize, {passive: true})
    this.el.addEventListener("mouseover", this.onTip)
    this.el.addEventListener("focusin", this.onTip)
  },

  updated() {
    const server = this.el.dataset.serverCollapsed === "true"
    const changed = server !== this.server
    this.server = server
    changed && this.apply(server)
    this.paintToggles()
  },

  destroyed() {
    document.removeEventListener("click", this.onClick)
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("resize", this.onResize)
    this.el.removeEventListener("mouseover", this.onTip)
    this.el.removeEventListener("focusin", this.onTip)
  },

  collapsed() {
    return this.el.dataset.collapsed === "true"
  },

  apply(collapsed) {
    this.el.dataset.collapsed = String(collapsed)
    this.paintToggles()
  },

  paintToggles() {
    document
      .querySelectorAll(`[data-rail-toggle="${CSS.escape(this.el.id)}"]`)
      .forEach((toggle) => toggle.setAttribute("aria-pressed", String(this.collapsed())))
  },

  choose(collapsed) {
    this.apply(collapsed)
    this.el.dataset.persist === "true" && write(RAIL_KEY, railValue(collapsed))
    this.push(collapsed)
  },

  push(collapsed) {
    const event = this.el.dataset.onCollapse
    event && this.pushEventTo(this.el.dataset.target || this.el, event, {id: this.el.id, collapsed})
  },

  mobile(open) {
    this.el.dataset.mobileOpen = String(open)
    this.el.querySelector("[data-mobile-toggle]")?.setAttribute("aria-expanded", String(open))
  },

  click(event) {
    const toggle = event.target.closest("[data-rail-toggle]")
    const inside = this.el.contains(event.target)
    const actions = [
      [toggle?.dataset.railToggle === this.el.id, () => this.choose(!this.collapsed())],
      [inside && event.target.closest("[data-mobile-toggle]"), () => this.mobile(this.el.dataset.mobileOpen !== "true")],
      [inside && event.target.closest("[data-module]") && this.collapsed() && !isMobile(window.innerWidth), () => this.choose(false)],
      [inside && event.target.closest("a[href]") && this.el.dataset.mobileOpen === "true", () => this.mobile(false)],
    ]
    actions.filter(([applies]) => applies).forEach(([, action]) => action())
  },
}

/** The page header's clock: the date and time in the page's language, kept current every 30 seconds. */
const ShellClock = {
  mounted() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 30000)
  },

  updated() {
    this.tick()
  },

  destroyed() {
    clearInterval(this.timer)
  },

  tick() {
    this.el.textContent = clockText(new Date(), this.el.dataset.locale || undefined)
  },
}

export default {
  "LineaUI.ShellRail": ShellRail,
  "LineaUI.ShellClock": ShellClock,
  "LineaUI.AppShell": AppShell,
  "LineaUI.SidebarGroup": SidebarGroup,
  "LineaUI.ShellPopper": ShellPopper,
  "LineaUI.ShellTooltips": ShellTooltips,
  "LineaUI.RightSidebar": RightSidebar,
}
