/**
 * LineaUI's LiveView hooks. In the app's app.js:
 *
 *   import {Hooks as LineaHooks} from "linea_ui"
 *   new LiveSocket("/live", Socket, {hooks: {...LineaHooks}, ...})
 *
 * Every hook is registered as `LineaUI.<Name>`, the value the components put in `phx-hook`.
 */
import AiComposer from "./hooks/ai_composer.js"
import Autocomplete from "./hooks/autocomplete.js"
import BulkBar from "./hooks/bulk_bar.js"
import Calendar from "./hooks/calendar.js"
import CardTable from "./hooks/card_table.js"
import Carousel from "./hooks/carousel.js"
import Chart from "./hooks/chart.js"
import Clipboard from "./hooks/clipboard.js"
import CommandPalette from "./hooks/command_palette.js"
import ColorPicker from "./hooks/color_picker.js"
import DataTable from "./hooks/data_table.js"
import DatePicker from "./hooks/date_picker.js"
import DatetimePicker from "./hooks/datetime_picker.js"
import Dialog from "./hooks/dialog.js"
import ActionMenu from "./hooks/action_menu.js"
import Dropdown from "./hooks/dropdown.js"
import Fab from "./hooks/fab.js"
import InputMask from "./hooks/input_mask.js"
import InputSuffix from "./hooks/input_suffix.js"
import LandingNav from "./hooks/landing_nav.js"
import Layout from "./hooks/layout.js"
import NumberInput from "./hooks/number_input.js"
import Otp from "./hooks/otp.js"
import PhoneInput from "./hooks/phone_input.js"
import Popover from "./hooks/popover.js"
import Range from "./hooks/range.js"
import ScrollBottom from "./hooks/scroll_bottom.js"
import Segmented from "./hooks/segmented.js"
import Select from "./hooks/select.js"
import Sidebar from "./hooks/sidebar.js"
import SignaturePad from "./hooks/signature_pad.js"
import Sortable from "./hooks/sortable.js"
import Tabs from "./hooks/tabs.js"
import TagsInput from "./hooks/tags_input.js"
import Textarea from "./hooks/textarea.js"
import TextareaTokens from "./hooks/textarea_tokens.js"
import TextEditor from "./hooks/text_editor.js"
import Theme from "./hooks/theme.js"
import TimePicker from "./hooks/time_picker.js"
import Timer from "./hooks/timer.js"
import Toast from "./hooks/toast.js"
import Tooltip from "./hooks/tooltip.js"
import Treeview from "./hooks/treeview.js"
import Upload from "./hooks/upload.js"

// Named exports, one per hook, for apps that bundle only the hooks they use (see the README):
//   import {Tooltip, Dropdown} from "linea_ui"; new LiveSocket(..., {hooks: {...Tooltip, ...Dropdown}})
export {ActionMenu, AiComposer, Autocomplete, BulkBar, Calendar, CardTable, Carousel, Chart, Clipboard, ColorPicker, CommandPalette, DataTable, DatePicker, DatetimePicker, Dialog, Dropdown, Fab, InputMask, InputSuffix, LandingNav, Layout, NumberInput, Otp, PhoneInput, Popover, Range, ScrollBottom, Segmented, Select, Sidebar, SignaturePad, Sortable, Tabs, TagsInput, Textarea, TextareaTokens, TextEditor, Theme, TimePicker, Timer, Toast, Tooltip, Treeview, Upload}

export const Hooks = /* @__PURE__ */ Object.assign(
  {},
  AiComposer,
  Autocomplete,
  BulkBar,
  Calendar,
  CardTable,
  Carousel,
  Chart,
  Clipboard,
  CommandPalette,
  ColorPicker,
  DataTable,
  DatePicker,
  DatetimePicker,
  Dialog,
  ActionMenu,
  Dropdown,
  Fab,
  InputMask,
  InputSuffix,
  LandingNav,
  Layout,
  NumberInput,
  Otp,
  PhoneInput,
  Popover,
  Range,
  ScrollBottom,
  Segmented,
  Select,
  Sidebar,
  SignaturePad,
  Sortable,
  Tabs,
  TagsInput,
  Textarea,
  TextareaTokens,
  TextEditor,
  Theme,
  TimePicker,
  Timer,
  Toast,
  Tooltip,
  Treeview,
  Upload,
)

export default Hooks
