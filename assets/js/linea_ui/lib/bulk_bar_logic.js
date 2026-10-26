/** Whether an Escape keydown should clear the selection: not when it was meant for something else (an open list, a field). */
export const clearsOnEscape = (event, {listOpen = false} = {}) =>
  event.key === "Escape" && !event.defaultPrevented && !event.isComposing && !listOpen
