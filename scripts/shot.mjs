// Screenshots a page with headless Chromium over the DevTools protocol (no npm packages).
//
//   node scripts/shot.mjs <url> <out.png> [--dark] [--width=1440] [--height=900] [--full]
//                         [--select=<css>] [--eval=<js>] [--wait=<ms>]
//
// --dark       sets LineOne's localStorage key ("dark-mode" = "dark") and reloads, which is also what
//              the preview reads; `?theme=dark` works on the preview too.
// --click      a real click on the first element matching the selector (focus, a row that opens a panel).
// --hover      (after --click) moves the real mouse over the first element matching the selector (a :hover panel, a tooltip).
// --settle     milliseconds to wait after --click and --hover, before the shot (a delayed close, a transition).
// --select     clips the shot to the first element matching the selector (scrolled into view).
// --eval       runs JavaScript in the page before the shot (click a trigger, open a menu...).
// --full       the whole page height instead of the viewport.
import {spawn} from "node:child_process"
import {mkdtempSync, writeFileSync} from "node:fs"
import {tmpdir} from "node:os"
import {join} from "node:path"

const [url, out, ...flags] = process.argv.slice(2)
const opt = Object.fromEntries(flags.map((f) => f.replace(/^--/, "").split(/=(.*)/s)).map(([k, v]) => [k, v ?? true]))
const width = Number(opt.width ?? 1440)
const height = Number(opt.height ?? 900)
const wait = Number(opt.wait ?? 1200)
const port = 9300 + Math.floor(Math.random() * 600)

const chrome = spawn("chromium", [
  "--headless=new", `--remote-debugging-port=${port}`, "--no-first-run", "--hide-scrollbars",
  "--disable-gpu", `--user-data-dir=${mkdtempSync(join(tmpdir(), "shot-"))}`, `--window-size=${width},${height}`, "about:blank",
], {stdio: "ignore"})

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

const target = async () => {
  for (let i = 0; i < 300; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json`)).json()
      const page = list.find((t) => t.type === "page")
      if (page) return page.webSocketDebuggerUrl
    } catch {}
    await sleep(100)
  }
  throw new Error("chromium did not start")
}

const ws = new WebSocket(await target())
await new Promise((r) => ws.addEventListener("open", r))
let seq = 0
const pending = new Map()
ws.addEventListener("message", ({data}) => {
  const msg = JSON.parse(data)
  msg.id && pending.get(msg.id)?.(msg)
})
const send = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const id = ++seq
    pending.set(id, (msg) => (msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result)))
    ws.send(JSON.stringify({id, method, params}))
  })
const evaluate = async (expression) =>
  (await send("Runtime.evaluate", {expression, awaitPromise: true, returnByValue: true})).result.value

try {
  await send("Page.enable")
  await send("Emulation.setFocusEmulationEnabled", {enabled: true}) // a headless page has no focus, so :focus would never match
  await send("Emulation.setDeviceMetricsOverride", {width, height, deviceScaleFactor: 1, mobile: false})
  await send("Page.navigate", {url})
  await sleep(wait)
  if (opt.dark) {
    await evaluate(`localStorage.setItem("dark-mode", "dark")`)
    await send("Page.reload")
    await sleep(wait)
  }
  if (opt.eval) {
    await evaluate(opt.eval)
    await sleep(400)
  }
  if (opt.click) {
    const at = await evaluate(`(() => {
      const el = document.querySelector(${JSON.stringify(opt.click)})
      if (!el) return null
      el.scrollIntoView({block: "center"})
      const r = el.getBoundingClientRect()
      return {x: r.left + r.width / 2, y: r.top + r.height / 2}
    })()`)
    if (!at) throw new Error(`no element matches ${opt.click}`)
    for (const type of ["mousePressed", "mouseReleased"])
      await send("Input.dispatchMouseEvent", {type, x: at.x, y: at.y, button: "left", clickCount: 1})
    await sleep(500)
  }
  if (opt.hover) {
    const at = await evaluate(`(() => {
      const el = document.querySelector(${JSON.stringify(opt.hover)})
      if (!el) return null
      el.scrollIntoView({block: "center"})
      const r = el.getBoundingClientRect()
      return {x: r.left + r.width / 2, y: r.top + r.height / 2}
    })()`)
    if (!at) throw new Error(`no element matches ${opt.hover}`)
    await send("Input.dispatchMouseEvent", {type: "mouseMoved", x: at.x, y: at.y})
    await sleep(500 + Number(opt.settle ?? 0))
  }
  if (opt.full || opt.select) {
    const docHeight = await evaluate(`document.documentElement.scrollHeight`)
    await send("Emulation.setDeviceMetricsOverride", {width, height: docHeight, deviceScaleFactor: 1, mobile: false})
    await sleep(700)
  }
  let clip
  if (opt.select) {
    clip = await evaluate(`(() => {
      const el = document.querySelector(${JSON.stringify(opt.select)})
      if (!el) return null
      const r = el.getBoundingClientRect()
      return {x: r.left + scrollX, y: r.top + scrollY, width: r.width, height: r.height, scale: 1}
    })()`)
    if (!clip) throw new Error(`no element matches ${opt.select}`)
  }
  const shot = await send("Page.captureScreenshot", {format: "png", captureBeyondViewport: false, ...(clip ? {clip} : {})})
  writeFileSync(out, Buffer.from(shot.data, "base64"))
  console.log(out)
} finally {
  ws.close()
  chrome.kill()
}
