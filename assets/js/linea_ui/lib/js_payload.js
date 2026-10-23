/**
 * A component's `on_*` callback given as `%JS{}` arrives encoded (`[["push", {"event": ...}], ...]`).
 * Before running it, the payload the component would have pushed (`id`, `value`, `index`...) is merged
 * into the `value` of every `push` op, so `on_close={JS.push("closed")}` receives `%{"id" => ...}` just like
 * `on_close="closed"` does. Values the caller wrote in `JS.push(value: ...)` win over the payload.
 *
 * @param {string} encoded the JSON the server rendered for the `%JS{}`
 * @param {object} payload
 * @returns {string}
 */
export const withPayload = (encoded, payload = {}) => {
  const ops = JSON.parse(encoded)
  return JSON.stringify(
    ops.map(([kind, args]) => (kind === "push" ? [kind, {...args, value: {...payload, ...(args.value || {})}}] : [kind, args])),
  )
}

/** Runs an encoded `%JS{}` on `el` with `payload` merged into its pushes; nothing for an empty or missing command. */
export const execWithPayload = (liveSocket, el, encoded, payload) =>
  encoded && encoded !== "[]" && liveSocket.execJS(el, withPayload(encoded, payload))
