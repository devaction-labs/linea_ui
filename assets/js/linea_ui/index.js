/**
 * LineaUI's LiveView hooks. In the app's app.js:
 *
 *   import {Hooks as LineaHooks} from "linea_ui"
 *   new LiveSocket("/live", Socket, {hooks: {...LineaHooks}, ...})
 *
 * Every hook is registered as `LineaUI.<Name>`, the value the components put in `phx-hook`.
 */
import Autocomplete from "./hooks/autocomplete.js"
import Calendar from "./hooks/calendar.js"
import Carousel from "./hooks/carousel.js"
import Chart from "./hooks/chart.js"
import Clipboard from "./hooks/clipboard.js"
import CommandPalette from "./hooks/command_palette.js"
import ColorPicker from "./hooks/color_picker.js"
import DataTable from "./hooks/data_table.js"
import DatePicker from "./hooks/date_picker.js"
import DatetimePicker from "./hooks/datetime_picker.js"
import Dialog from "./hooks/dialog.js"
import Dropdown from "./hooks/dropdown.js"
import Fab from "./hooks/fab.js"
import InputMask from "./hooks/input_mask.js"
import NumberInput from "./hooks/number_input.js"
import Popover from "./hooks/popover.js"
import Range from "./hooks/range.js"
import Segmented from "./hooks/segmented.js"
import Select from "./hooks/select.js"
import Sidebar from "./hooks/sidebar.js"
import SignaturePad from "./hooks/signature_pad.js"
import Tabs from "./hooks/tabs.js"
import TagsInput from "./hooks/tags_input.js"
import TextEditor from "./hooks/text_editor.js"
import Theme from "./hooks/theme.js"
import TimePicker from "./hooks/time_picker.js"
import Timer from "./hooks/timer.js"
import Toast from "./hooks/toast.js"
import Tooltip from "./hooks/tooltip.js"
import Treeview from "./hooks/treeview.js"
import Upload from "./hooks/upload.js"

export const Hooks = {
  ...Autocomplete,
  ...Calendar,
  ...Carousel,
  ...Chart,
  ...Clipboard,
  ...CommandPalette,
  ...ColorPicker,
  ...DataTable,
  ...DatePicker,
  ...DatetimePicker,
  ...Dialog,
  ...Dropdown,
  ...Fab,
  ...InputMask,
  ...NumberInput,
  ...Popover,
  ...Range,
  ...Segmented,
  ...Select,
  ...Sidebar,
  ...SignaturePad,
  ...Tabs,
  ...TagsInput,
  ...TextEditor,
  ...Theme,
  ...TimePicker,
  ...Timer,
  ...Toast,
  ...Tooltip,
  ...Treeview,
  ...Upload,
}

export default Hooks
