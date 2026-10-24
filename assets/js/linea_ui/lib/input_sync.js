export const nextValue = ({pending, current, server}) =>
  pending && typeof server === "string" && current !== server ? server : null
