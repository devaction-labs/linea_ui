export const THRESHOLD = 32

/**
 * How far the box is from its end, in pixels.
 *
 * @param {{scrollTop: number, scrollHeight: number, clientHeight: number}} box
 * @returns {number}
 */
export const distanceFromEnd = ({scrollTop, scrollHeight, clientHeight}) => Math.max(scrollHeight - clientHeight - scrollTop, 0)

/**
 * Whether the reader is at the end: within `threshold` pixels of it counts, so a few pixels of slack
 * do not unpin the box.
 *
 * @param {{scrollTop: number, scrollHeight: number, clientHeight: number}} box
 * @param {number} [threshold]
 * @returns {boolean}
 */
export const pinned = (box, threshold = THRESHOLD) => distanceFromEnd(box) <= threshold

/**
 * Whether the box is pinned after a scroll. Moving down keeps a pinned box pinned even when the end moved
 * further away meanwhile (content added while a smooth scroll is still running); moving up unpins it unless it
 * stays within the threshold.
 *
 * @param {{was: boolean, box: {scrollTop: number, scrollHeight: number, clientHeight: number}, previousTop: number}} state
 * @returns {boolean}
 */
export const afterScroll = ({was, box, previousTop}) => pinned(box) || (was && box.scrollTop >= previousTop)

/**
 * The `scrollTop` that shows the end of the box.
 *
 * @param {{scrollHeight: number, clientHeight: number}} box
 * @returns {number}
 */
export const endOf = ({scrollHeight, clientHeight}) => Math.max(scrollHeight - clientHeight, 0)
