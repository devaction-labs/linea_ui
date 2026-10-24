defmodule LineaUI.Components.Icon do
  @moduledoc """
  Icons: Hugeicons Stroke Rounded by name, and the small glyphs LineaUI's own components draw (the cross of a
  toast, the chevron of a select, the check of a checkbox, the tools of the text editor).

      <.icon name="huge-search-01" class="size-4" />
      <.glyph name={:chevron_down} class="size-4" />

  `icon/1` draws `huge-*` classes from Hugeicons (the free Stroke Rounded set, which the app vendors and
  `assets/css/hugeicons.cjs` turns into classes; see the README) and passes any other class name through, so
  `name="fa-solid fa-house"` works with Font Awesome. Write the name in full, never interpolated, or Tailwind
  cannot see the class.

  `glyph/1` is for the components: it draws LineOne's own SVG by default and the matching Hugeicons icon when the
  app sets

      config :linea_ui, :icons, :hugeicons

  The setting is read when the page renders; the hooks that draw glyphs in the browser read it from the
  `data-icons` attribute of their element (see `icon_set/0`). The table below is mirrored in
  `assets/js/linea_ui/lib/glyphs.js` for the glyphs those hooks draw, and a test keeps the two equal.

  The big two-tone icons of the sidebar, the arrows of tooltips and popovers and the spinner are artwork, not
  glyphs, and stay as they are in every set.
  """

  use LineaUI.Component

  @lineone %{
    info_circle: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />|
    },
    warning: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />|
    },
    check_circle: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />|
    },
    error_circle: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />|
    },
    close: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />|
    },
    check: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />|
    },
    chevron_down: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />|
    },
    chevron_up: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M5 15l7-7 7 7" />|
    },
    chevron_left: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />|
    },
    chevron_right: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />|
    },
    plus: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />|
    },
    minus: %{
      view: "0 0 24 24",
      paint: :stroke,
      body: ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M20 12H4" />|
    },
    search: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />|
    },
    dots_horizontal: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z" />|
    },
    dots_vertical: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />|
    },
    clock: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />|
    },
    calendar: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />|
    },
    filter: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M18 11.5H6M21 4H3m6 15h6" />|
    },
    bell: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M15.375 17.556h-6.75m6.75 0H21l-1.58-1.562a2.254 2.254 0 01-.67-1.596v-3.51a6.612 6.612 0 00-1.238-3.85 6.744 6.744 0 00-3.262-2.437v-.379c0-.59-.237-1.154-.659-1.571A2.265 2.265 0 0012 2c-.597 0-1.169.234-1.591.65a2.208 2.208 0 00-.659 1.572v.38c-2.621.915-4.5 3.385-4.5 6.287v3.51c0 .598-.24 1.172-.67 1.595L3 17.556h12.375zm0 0v1.11c0 .885-.356 1.733-.989 2.358A3.397 3.397 0 0112 22a3.397 3.397 0 01-2.386-.976 3.313 3.313 0 01-.989-2.357v-1.111h6.75z" />|
    },
    apps: %{
      view: "0 0 24 24",
      paint: :stroke,
      body:
        ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />|
    },
    search_solid: %{
      view: "0 0 24 24",
      paint: :fill,
      body:
        ~S|<path d="M3.316 13.781l.73-.171-.73.171zm0-5.457l.73.171-.73-.171zm15.473 0l.73-.171-.73.171zm0 5.457l.73.171-.73-.171zm-5.008 5.008l-.171-.73.171.73zm-5.457 0l-.171.73.171-.73zm0-15.473l-.171-.73.171.73zm5.457 0l.171-.73-.171.73zM20.47 21.53a.75.75 0 101.06-1.06l-1.06 1.06zM4.046 13.61a11.198 11.198 0 010-5.115l-1.46-.342a12.698 12.698 0 000 5.8l1.46-.343zm14.013-5.115a11.196 11.196 0 010 5.115l1.46.342a12.698 12.698 0 000-5.8l-1.46.343zm-4.45 9.564a11.196 11.196 0 01-5.114 0l-.342 1.46c1.907.448 3.892.448 5.8 0l-.343-1.46zM8.496 4.046a11.198 11.198 0 015.115 0l.342-1.46a12.698 12.698 0 00-5.8 0l.343 1.46zm0 14.013a5.97 5.97 0 01-4.45-4.45l-1.46.343a7.47 7.47 0 005.568 5.568l.342-1.46zm5.457 1.46a7.47 7.47 0 005.568-5.567l-1.46-.342a5.97 5.97 0 01-4.45 4.45l.342 1.46zM13.61 4.046a5.97 5.97 0 014.45 4.45l1.46-.343a7.47 7.47 0 00-5.568-5.567l-.342 1.46zm-5.457-1.46a7.47 7.47 0 00-5.567 5.567l1.46.342a5.97 5.97 0 014.45-4.45l-.343-1.46zm8.652 15.28l3.665 3.664 1.06-1.06-3.665-3.665-1.06 1.06z" />|
    },
    chevron_down_solid: %{
      view: "0 0 512 512",
      paint: :fill,
      body:
        ~S|<path d="M233.4 406.6c12.5 12.5 32.8 12.5 45.3 0l192-192c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L256 338.7 86.6 169.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3l192 192z" />|
    },
    chevron_right_solid: %{
      view: "0 0 20 20",
      paint: :fill,
      body:
        ~S|<path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />|
    },
    close_solid: %{
      view: "0 0 26 26",
      paint: :fill,
      body:
        ~S|<path fill-rule="nonzero" d="M11.586 13l-2.293 2.293a1 1 0 0 0 1.414 1.414L13 14.414l2.293 2.293a1 1 0 0 0 1.414-1.414L14.414 13l2.293-2.293a1 1 0 0 0-1.414-1.414L13 11.586l-2.293-2.293a1 1 0 0 0-1.414 1.414L11.586 13z" />|
    },
    carousel_arrow: %{
      view: "0 0 11 20",
      paint: :fill,
      body:
        ~S|<path d="M0.38296 20.0762C0.111788 19.805 0.111788 19.3654 0.38296 19.0942L9.19758 10.2796L0.38296 1.46497C0.111788 1.19379 0.111788 0.754138 0.38296 0.482966C0.654131 0.211794 1.09379 0.211794 1.36496 0.482966L10.4341 9.55214C10.8359 9.9539 10.8359 10.6053 10.4341 11.007L1.36496 20.0762C1.09379 20.3474 0.654131 20.3474 0.38296 20.0762Z" />|
    },
    angle_left: %{
      view: "0 0 17 17",
      paint: :bare,
      body:
        ~S|<path d="M5.207 8.471l7.146 7.147-0.707 0.707-7.853-7.854 7.854-7.853 0.707 0.707-7.147 7.146z" />|
    },
    angle_right: %{
      view: "0 0 17 17",
      paint: :bare,
      body:
        ~S|<path d="M13.207 8.472l-7.854 7.854-0.707-0.707 7.146-7.146-7.146-7.148 0.707-0.707 7.854 7.854z" />|
    },
    moon: %{
      view: "0 0 24 24",
      paint: :fill,
      body:
        ~S|<path d="M11.75 3.412a.818.818 0 01-.07.917 6.332 6.332 0 00-1.4 3.971c0 3.564 2.98 6.494 6.706 6.494a6.86 6.86 0 002.856-.617.818.818 0 011.1 1.047C19.593 18.614 16.218 21 12.283 21 7.18 21 3 16.973 3 11.956c0-4.563 3.46-8.31 7.925-8.948a.818.818 0 01.826.404z" />|
    },
    sun: %{
      view: "0 0 20 20",
      paint: :fill,
      body:
        ~S|<path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" />|
    },
    editor_align_center: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="14" x2="4" y1="14" y2="14"></line><line class="ql-stroke" x1="12" x2="6" y1="4" y2="4"></line>|
    },
    editor_align_justify: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="15" x2="3" y1="14" y2="14"></line><line class="ql-stroke" x1="15" x2="3" y1="4" y2="4"></line>|
    },
    editor_align_left: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="3" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="3" x2="13" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="9" y1="4" y2="4"></line>|
    },
    editor_align_right: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="15" x2="5" y1="14" y2="14"></line><line class="ql-stroke" x1="15" x2="9" y1="4" y2="4"></line>|
    },
    editor_blockquote: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<rect class="ql-fill ql-stroke" height="3" width="3" x="4" y="5"></rect><rect class="ql-fill ql-stroke" height="3" width="3" x="11" y="5"></rect><path class="ql-even ql-fill ql-stroke" d="M7,8c0,4.031-3,5-3,5"></path><path class="ql-even ql-fill ql-stroke" d="M14,8c0,4.031-3,5-3,5"></path>|
    },
    editor_bold: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-stroke" d="M5,4H9.5A2.5,2.5,0,0,1,12,6.5v0A2.5,2.5,0,0,1,9.5,9H5A0,0,0,0,1,5,9V4A0,0,0,0,1,5,4Z"></path><path class="ql-stroke" d="M5,9h5.5A2.5,2.5,0,0,1,13,11.5v0A2.5,2.5,0,0,1,10.5,14H5a0,0,0,0,1,0,0V9A0,0,0,0,1,5,9Z"></path>|
    },
    editor_clean: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="5" x2="13" y1="3" y2="3"></line><line class="ql-stroke" x1="6" x2="9.35" y1="12" y2="3"></line><line class="ql-stroke" x1="11" x2="15" y1="11" y2="15"></line><line class="ql-stroke" x1="15" x2="11" y1="11" y2="15"></line><rect class="ql-fill" height="1" rx="0.5" ry="0.5" width="7" x="2" y="14"></rect>|
    },
    editor_code: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<polyline class="ql-even ql-stroke" points="5 7 3 9 5 11"></polyline><polyline class="ql-even ql-stroke" points="13 7 15 9 13 11"></polyline><line class="ql-stroke" x1="10" x2="8" y1="5" y2="13"></line>|
    },
    editor_code_block: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<polyline class="ql-even ql-stroke" points="5 7 3 9 5 11"></polyline><polyline class="ql-even ql-stroke" points="13 7 15 9 13 11"></polyline><line class="ql-stroke" x1="10" x2="8" y1="5" y2="13"></line>|
    },
    editor_direction: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<polygon class="ql-stroke ql-fill" points="3 11 5 9 3 7 3 11"></polygon><line class="ql-stroke ql-fill" x1="15" x2="11" y1="4" y2="4"></line><path class="ql-fill" d="M11,3a3,3,0,0,0,0,6h1V3H11Z"></path><rect class="ql-fill" height="11" width="1" x="11" y="4"></rect><rect class="ql-fill" height="11" width="1" x="13" y="4"></rect>|
    },
    editor_direction_active: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<polygon class="ql-stroke ql-fill" points="15 12 13 10 15 8 15 12"></polygon><line class="ql-stroke ql-fill" x1="9" x2="5" y1="4" y2="4"></line><path class="ql-fill" d="M5,3A3,3,0,0,0,5,9H6V3H5Z"></path><rect class="ql-fill" height="11" width="1" x="5" y="4"></rect><rect class="ql-fill" height="11" width="1" x="7" y="4"></rect>|
    },
    editor_dropdown: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<polygon class="ql-stroke" points="7 11 9 13 11 11 7 11"></polygon><polygon class="ql-stroke" points="7 7 9 5 11 7 7 7"></polygon>|
    },
    editor_header_1: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-fill" d="M10,4V14a1,1,0,0,1-2,0V10H3v4a1,1,0,0,1-2,0V4A1,1,0,0,1,3,4V8H8V4a1,1,0,0,1,2,0Zm6.06787,9.209H14.98975V7.59863a.54085.54085,0,0,0-.605-.60547h-.62744a1.01119,1.01119,0,0,0-.748.29688L11.645,8.56641a.5435.5435,0,0,0-.022.8584l.28613.30762a.53861.53861,0,0,0,.84717.0332l.09912-.08789a1.2137,1.2137,0,0,0,.2417-.35254h.02246s-.01123.30859-.01123.60547V13.209H12.041a.54085.54085,0,0,0-.605.60547v.43945a.54085.54085,0,0,0,.605.60547h4.02686a.54085.54085,0,0,0,.605-.60547v-.43945A.54085.54085,0,0,0,16.06787,13.209Z"></path>|
    },
    editor_header_2: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-fill" d="M16.73975,13.81445v.43945a.54085.54085,0,0,1-.605.60547H11.855a.58392.58392,0,0,1-.64893-.60547V14.0127c0-2.90527,3.39941-3.42187,3.39941-4.55469a.77675.77675,0,0,0-.84717-.78125,1.17684,1.17684,0,0,0-.83594.38477c-.2749.26367-.561.374-.85791.13184l-.4292-.34082c-.30811-.24219-.38525-.51758-.1543-.81445a2.97155,2.97155,0,0,1,2.45361-1.17676,2.45393,2.45393,0,0,1,2.68408,2.40918c0,2.45312-3.1792,2.92676-3.27832,3.93848h2.79443A.54085.54085,0,0,1,16.73975,13.81445ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"></path>|
    },
    editor_indent_minus1: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="3" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="9" x2="15" y1="9" y2="9"></line><polyline class="ql-stroke" points="5 7 5 11 3 9 5 7"></polyline>|
    },
    editor_indent_plus1: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="3" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="9" x2="15" y1="9" y2="9"></line><polyline class="ql-fill ql-stroke" points="3 7 3 11 5 9 3 7"></polyline>|
    },
    editor_italic: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="7" x2="13" y1="4" y2="4"></line><line class="ql-stroke" x1="5" x2="11" y1="14" y2="14"></line><line class="ql-stroke" x1="8" x2="10" y1="14" y2="4"></line>|
    },
    editor_link: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="7" x2="11" y1="7" y2="11"></line><path class="ql-even ql-stroke" d="M8.9,4.577a3.476,3.476,0,0,1,.36,4.679A3.476,3.476,0,0,1,4.577,8.9C3.185,7.5,2.035,6.4,4.217,4.217S7.5,3.185,8.9,4.577Z"></path><path class="ql-even ql-stroke" d="M13.423,9.1a3.476,3.476,0,0,0-4.679-.36,3.476,3.476,0,0,0,.36,4.679c1.392,1.392,2.5,2.542,4.679.36S14.815,10.5,13.423,9.1Z"></path>|
    },
    editor_list_bullet: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="6" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="6" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="6" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="3" y1="4" y2="4"></line><line class="ql-stroke" x1="3" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="3" x2="3" y1="14" y2="14"></line>|
    },
    editor_list_ordered: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="7" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="7" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="7" x2="15" y1="14" y2="14"></line><line class="ql-stroke ql-thin" x1="2.5" x2="4.5" y1="5.5" y2="5.5"></line><path class="ql-fill" d="M3.5,6A0.5,0.5,0,0,1,3,5.5V3.085l-0.276.138A0.5,0.5,0,0,1,2.053,3c-0.124-.247-0.023-0.324.224-0.447l1-.5A0.5,0.5,0,0,1,4,2.5v3A0.5,0.5,0,0,1,3.5,6Z"></path><path class="ql-stroke ql-thin" d="M4.5,10.5h-2c0-.234,1.85-1.076,1.85-2.234A0.959,0.959,0,0,0,2.5,8.156"></path><path class="ql-stroke ql-thin" d="M2.5,14.846a0.959,0.959,0,0,0,1.85-.109A0.7,0.7,0,0,0,3.75,14a0.688,0.688,0,0,0,.6-0.736,0.959,0.959,0,0,0-1.85-.109"></path>|
    },
    editor_picker_align: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke" x1="3" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="3" x2="13" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="9" y1="4" y2="4"></line>|
    },
    editor_picker_background: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<g class="ql-fill ql-color-label"><polygon points="6 6.868 6 6 5 6 5 7 5.942 7 6 6.868"></polygon><rect height="1" width="1" x="4" y="4"></rect><polygon points="6.817 5 6 5 6 6 6.38 6 6.817 5"></polygon><rect height="1" width="1" x="2" y="6"></rect><rect height="1" width="1" x="3" y="5"></rect><rect height="1" width="1" x="4" y="7"></rect><polygon points="4 11.439 4 11 3 11 3 12 3.755 12 4 11.439"></polygon><rect height="1" width="1" x="2" y="12"></rect><rect height="1" width="1" x="2" y="9"></rect><rect height="1" width="1" x="2" y="15"></rect><polygon points="4.63 10 4 10 4 11 4.192 11 4.63 10"></polygon><rect height="1" width="1" x="3" y="8"></rect><path d="M10.832,4.2L11,4.582V4H10.708A1.948,1.948,0,0,1,10.832,4.2Z"></path><path d="M7,4.582L7.168,4.2A1.929,1.929,0,0,1,7.292,4H7V4.582Z"></path><path d="M8,13H7.683l-0.351.8a1.933,1.933,0,0,1-.124.2H8V13Z"></path><rect height="1" width="1" x="12" y="2"></rect><rect height="1" width="1" x="11" y="3"></rect><path d="M9,3H8V3.282A1.985,1.985,0,0,1,9,3Z"></path><rect height="1" width="1" x="2" y="3"></rect><rect height="1" width="1" x="6" y="2"></rect><rect height="1" width="1" x="3" y="2"></rect><rect height="1" width="1" x="5" y="3"></rect><rect height="1" width="1" x="9" y="2"></rect><rect height="1" width="1" x="15" y="14"></rect><polygon points="13.447 10.174 13.469 10.225 13.472 10.232 13.808 11 14 11 14 10 13.37 10 13.447 10.174"></polygon><rect height="1" width="1" x="13" y="7"></rect><rect height="1" width="1" x="15" y="5"></rect><rect height="1" width="1" x="14" y="6"></rect><rect height="1" width="1" x="15" y="8"></rect><rect height="1" width="1" x="14" y="9"></rect><path d="M3.775,14H3v1H4V14.314A1.97,1.97,0,0,1,3.775,14Z"></path><rect height="1" width="1" x="14" y="3"></rect><polygon points="12 6.868 12 6 11.62 6 12 6.868"></polygon><rect height="1" width="1" x="15" y="2"></rect><rect height="1" width="1" x="12" y="5"></rect><rect height="1" width="1" x="13" y="4"></rect><polygon points="12.933 9 13 9 13 8 12.495 8 12.933 9"></polygon><rect height="1" width="1" x="9" y="14"></rect><rect height="1" width="1" x="8" y="15"></rect><path d="M6,14.926V15H7V14.316A1.993,1.993,0,0,1,6,14.926Z"></path><rect height="1" width="1" x="5" y="15"></rect><path d="M10.668,13.8L10.317,13H10v1h0.792A1.947,1.947,0,0,1,10.668,13.8Z"></path><rect height="1" width="1" x="11" y="15"></rect><path d="M14.332,12.2a1.99,1.99,0,0,1,.166.8H15V12H14.245Z"></path><rect height="1" width="1" x="14" y="15"></rect><rect height="1" width="1" x="15" y="11"></rect></g><polyline class="ql-stroke" points="5.5 13 9 5 12.5 13"></polyline><line class="ql-stroke" x1="11.63" x2="6.38" y1="11" y2="11"></line>|
    },
    editor_picker_color: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-color-label ql-stroke ql-transparent" x1="3" x2="15" y1="15" y2="15"></line><polyline class="ql-stroke" points="5.5 11 9 3 12.5 11"></polyline><line class="ql-stroke" x1="11.63" x2="6.38" y1="9" y2="9"></line>|
    },
    editor_script_sub: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-fill" d="M15.5,15H13.861a3.858,3.858,0,0,0,1.914-2.975,1.8,1.8,0,0,0-1.6-1.751A1.921,1.921,0,0,0,12.021,11.7a0.50013,0.50013,0,1,0,.957.291h0a0.914,0.914,0,0,1,1.053-.725,0.81,0.81,0,0,1,.744.762c0,1.076-1.16971,1.86982-1.93971,2.43082A1.45639,1.45639,0,0,0,12,15.5a0.5,0.5,0,0,0,.5.5h3A0.5,0.5,0,0,0,15.5,15Z"></path><path class="ql-fill" d="M9.65,5.241a1,1,0,0,0-1.409.108L6,7.964,3.759,5.349A1,1,0,0,0,2.192,6.59178Q2.21541,6.6213,2.241,6.649L4.684,9.5,2.241,12.35A1,1,0,0,0,3.71,13.70722q0.02557-.02768.049-0.05722L6,11.036,8.241,13.65a1,1,0,1,0,1.567-1.24277Q9.78459,12.3777,9.759,12.35L7.316,9.5,9.759,6.651A1,1,0,0,0,9.65,5.241Z"></path>|
    },
    editor_script_super: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-fill" d="M15.5,7H13.861a4.015,4.015,0,0,0,1.914-2.975,1.8,1.8,0,0,0-1.6-1.751A1.922,1.922,0,0,0,12.021,3.7a0.5,0.5,0,1,0,.957.291,0.917,0.917,0,0,1,1.053-.725,0.81,0.81,0,0,1,.744.762c0,1.077-1.164,1.925-1.934,2.486A1.423,1.423,0,0,0,12,7.5a0.5,0.5,0,0,0,.5.5h3A0.5,0.5,0,0,0,15.5,7Z"></path><path class="ql-fill" d="M9.651,5.241a1,1,0,0,0-1.41.108L6,7.964,3.759,5.349a1,1,0,1,0-1.519,1.3L4.683,9.5,2.241,12.35a1,1,0,1,0,1.519,1.3L6,11.036,8.241,13.65a1,1,0,0,0,1.519-1.3L7.317,9.5,9.759,6.651A1,1,0,0,0,9.651,5.241Z"></path>|
    },
    editor_strike: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<line class="ql-stroke ql-thin" x1="15.5" x2="2.5" y1="8.5" y2="9.5"></line><path class="ql-fill" d="M9.007,8C6.542,7.791,6,7.519,6,6.5,6,5.792,7.283,5,9,5c1.571,0,2.765.679,2.969,1.309a1,1,0,0,0,1.9-.617C13.356,4.106,11.354,3,9,3,6.2,3,4,4.538,4,6.5a3.2,3.2,0,0,0,.5,1.843Z"></path><path class="ql-fill" d="M8.984,10C11.457,10.208,12,10.479,12,11.5c0,0.708-1.283,1.5-3,1.5-1.571,0-2.765-.679-2.969-1.309a1,1,0,1,0-1.9.617C4.644,13.894,6.646,15,9,15c2.8,0,5-1.538,5-3.5a3.2,3.2,0,0,0-.5-1.843Z"></path>|
    },
    editor_underline: %{
      view: "0 0 18 18",
      paint: :bare,
      body:
        ~S|<path class="ql-stroke" d="M5,3V9a4.012,4.012,0,0,0,4,4H9a4.012,4.012,0,0,0,4-4V3"></path><rect class="ql-fill" height="1" rx="0.5" ry="0.5" width="12" x="3" y="15"></rect>|
    }
  }

  @hugeicons %{
    info_circle: "huge-information-circle",
    warning: "huge-alert-02",
    check_circle: "huge-checkmark-circle-02",
    error_circle: "huge-cancel-circle",
    close: "huge-cancel-01",
    check: "huge-tick-02",
    chevron_down: "huge-arrow-down-01",
    chevron_up: "huge-arrow-up-01",
    chevron_left: "huge-arrow-left-01",
    chevron_right: "huge-arrow-right-01",
    plus: "huge-plus-sign",
    minus: "huge-minus-sign",
    search: "huge-search-01",
    dots_horizontal: "huge-more-horizontal",
    dots_vertical: "huge-more-vertical",
    clock: "huge-clock-01",
    calendar: "huge-calendar-03",
    filter: "huge-filter-horizontal",
    bell: "huge-notification-01",
    apps: "huge-layout-grid",
    search_solid: "huge-search-01",
    chevron_down_solid: "huge-arrow-down-01",
    chevron_right_solid: "huge-arrow-right-01",
    close_solid: "huge-cancel-01",
    carousel_arrow: "huge-arrow-right-01",
    angle_left: "huge-arrow-left-01",
    angle_right: "huge-arrow-right-01",
    moon: "huge-moon-02",
    sun: "huge-sun-03",
    editor_align_center: "huge-text-align-center",
    editor_align_justify: "huge-text-align-justify-center",
    editor_align_left: "huge-text-align-left",
    editor_align_right: "huge-text-align-right",
    editor_blockquote: "huge-quote-down",
    editor_bold: "huge-text-bold",
    editor_clean: "huge-text-clear",
    editor_code: "huge-source-code",
    editor_code_block: "huge-code-square",
    editor_direction: "huge-left-to-right-block-quote",
    editor_direction_active: "huge-right-to-left-block-quote",
    editor_dropdown: "huge-unfold-more",
    editor_header_1: "huge-heading-01",
    editor_header_2: "huge-heading-02",
    editor_indent_minus1: "huge-text-indent-less",
    editor_indent_plus1: "huge-text-indent-more",
    editor_italic: "huge-text-italic",
    editor_link: "huge-link-02",
    editor_list_bullet: "huge-left-to-right-list-bullet",
    editor_list_ordered: "huge-left-to-right-list-number",
    editor_picker_align: "huge-text-align-left",
    editor_picker_background: "huge-paint-bucket",
    editor_picker_color: "huge-text-color",
    editor_script_sub: "huge-text-subscript",
    editor_script_super: "huge-text-superscript",
    editor_strike: "huge-text-strikethrough",
    editor_underline: "huge-text-underline"
  }

  @markup Map.new(@lineone, fn {name, %{body: body} = entry} ->
            {name, entry |> Map.delete(:body) |> Map.put(:markup, {:safe, body})}
          end)

  @doc "The glyph names `glyph/1` knows."
  @spec glyph_names() :: [atom()]
  def glyph_names, do: @lineone |> Map.keys() |> Enum.sort()

  @doc "The glyph table of an icon set: `:lineone` maps names to `%{view, paint, body}`, `:hugeicons` to class names."
  @spec glyph_table(:lineone | :hugeicons) :: %{atom() => map() | String.t()}
  def glyph_table(:lineone), do: @lineone
  def glyph_table(:hugeicons), do: @hugeicons

  @doc "The icon set the app asked for: `:lineone` (the default) or `:hugeicons`."
  @spec icon_set() :: :lineone | :hugeicons
  def icon_set, do: Application.get_env(:linea_ui, :icons, :lineone)

  @doc "A Hugeicons icon by class name, or any other icon font class."
  attr :name, :string,
    required: true,
    doc: "`huge-search-01`, or any class such as `fa-solid fa-house`."

  attr :class, :any, default: "size-5"
  attr :rest, :global

  def icon(%{name: "huge-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" {@rest}></span>
    """
  end

  def icon(assigns) do
    ~H"""
    <i class={[@name, @class]} aria-hidden="true" {@rest}></i>
    """
  end

  @doc """
  One of the glyphs LineaUI's components draw, in the icon set of the app.

      <.glyph name={:chevron_down} class="size-4" />
      <.glyph name={:calendar} class="size-5" stroke_width="1.5" />
  """
  attr :name, :atom, required: true, values: Map.keys(@lineone)
  attr :class, :any, default: "size-4"

  attr :stroke_width, :any,
    default: "2",
    doc: "Only for LineOne's stroked SVGs; Hugeicons draw their own."

  attr :rest, :global

  def glyph(assigns), do: glyph(icon_set(), assigns)

  defp glyph(:hugeicons, assigns) do
    assigns = assign(assigns, :huge, Map.fetch!(@hugeicons, assigns.name))

    ~H"""
    <span class={[@huge, @class]} aria-hidden="true" {@rest}></span>
    """
  end

  defp glyph(:lineone, assigns) do
    %{view: view, paint: paint, markup: body} = Map.fetch!(@markup, assigns.name)

    assigns =
      assigns
      |> assign(:view, view)
      |> assign(:paint, paint(paint, assigns.stroke_width))
      |> assign(:body, body)

    ~H"""
    <svg class={@class} viewBox={@view} aria-hidden="true" {@paint} {@rest}>{@body}</svg>
    """
  end

  defp paint(:stroke, width),
    do: %{"fill" => "none", "stroke" => "currentColor", "stroke-width" => width}

  defp paint(:fill, _width), do: %{"fill" => "currentColor"}
  defp paint(:bare, _width), do: %{}
end
