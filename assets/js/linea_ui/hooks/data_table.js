import {indeterminate} from "../lib/data_table_logic.js"

const sync = (el) => {
  el.indeterminate = indeterminate(el.dataset.indeterminate, el.checked)
}

export default {
  "LineaUI.TableSelectAll": {
    mounted() {
      sync(this.el)
    },
    updated() {
      sync(this.el)
    },
  },
}
