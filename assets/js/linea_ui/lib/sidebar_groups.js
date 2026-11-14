/** The key the open groups of the menu `id` are kept under in `localStorage`. */
export const groupsKey = (id) => `linea-sidebar-groups:${id}`

const parsed = (raw) => {
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

/** The groups kept in `localStorage` (`{controlledId: open}`), or `{}` when the value is missing or broken. */
export const parseGroups = (raw) => {
  const value = parsed(raw)
  const plain = value !== null && typeof value === "object" && !Array.isArray(value)
  return plain ? Object.fromEntries(Object.entries(value).filter(([, open]) => typeof open === "boolean")) : {}
}

/** The value to keep for a list of `{id, open}` toggles. */
export const serializeGroups = (toggles) => JSON.stringify(Object.fromEntries(toggles.map(({id, open}) => [id, open])))
