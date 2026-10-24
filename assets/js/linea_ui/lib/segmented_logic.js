/**
 * What a segmented control decides without a DOM: the value after the server patched it (the person's choice stays
 * unless the server changed its own value) and whether pressing a segment changes anything.
 */

/**
 * The value after a patch: the server's when it differs from the one it sent last time, otherwise the one the
 * person has chosen in the browser.
 *
 * @param {{value: string, lastServer: string, server: string}} state
 */
export const adopt = ({value, lastServer, server}) => (server === lastServer ? value : server)

/** The value a press chooses, or `null` when the pressed segment is already the chosen one (nothing changes). */
export const pressed = (current, segment) => (segment === current ? null : segment)
