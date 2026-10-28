export const DEFAULT_AFTER_MS = 4000

export const afterOf = (value) => {
  const ms = Number(value)
  return Number.isFinite(ms) && ms > 0 ? ms : DEFAULT_AFTER_MS
}

const engaged = (state) => state.hover || state.focus
const settle = (state) => ({state, timer: engaged(state) ? "clear" : "start"})
const retract = (state) => ({state: {...state, expanded: false}, timer: "clear"})
const engage = (state) => ({state: {...state, expanded: true}, timer: "clear"})

const EVENTS = {
  enter: (state) => engage({...state, hover: true}),
  focus: (state) => engage({...state, focus: true}),
  leave: (state) => settle({...state, hover: false}),
  blur: (state) => settle({...state, focus: false}),
  idle: (state) => (engaged(state) ? {state, timer: "keep"} : retract(state)),
}

export const begin = (canHover) => {
  const state = {expanded: canHover, hover: false, focus: false}
  return {state, timer: canHover ? "start" : "clear"}
}

export const step = (state, event) => (EVENTS[event] ?? ((s) => ({state: s, timer: "keep"})))(state)

export const shapeOf = (state) => (state.expanded ? "expanded" : "collapsed")

/**
 * Where the arrow keys take the focus in a speed-dial: `index` is the action in focus (`-1` for the button), `count`
 * the number of actions. Down goes to the next action and up to the previous one, both wrapping; from the button, down
 * is the first and up the last; Home and End are the ends. Anything else keeps the focus where it is (`null`).
 */
export const dialTarget = (count, index, key) => {
  const moves = {
    ArrowDown: () => (index < 0 ? 0 : (index + 1) % count),
    ArrowUp: () => (index < 0 ? count - 1 : (index - 1 + count) % count),
    Home: () => 0,
    End: () => count - 1,
  }
  return count > 0 && key in moves ? moves[key]() : null
}
