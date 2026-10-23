/**
 * Which tab is selected after the server patched the tabs. The tab the person chose in the browser stays,
 * unless the server has since changed its own selection (then the server wins) or that tab is gone.
 *
 * @param {{chosen: string, lastServer: string, server: string, ids: string[]}} state `chosen` is `""` when the
 *   person has not chosen; `lastServer` and `server` are the server's selection before and after the patch
 * @returns {{selected: string, chosen: string, lastServer: string}}
 */
export const resolveSelection = ({chosen, lastServer, server, ids}) =>
  chosen && server === lastServer && ids.includes(chosen)
    ? {selected: chosen, chosen, lastServer: server}
    : {selected: server, chosen: "", lastServer: server}

/** The tabs a key can move to: every tab but the disabled ones, keeping the order. */
export const openTabs = (tabs) => tabs.filter((tab) => !tab.disabled)
