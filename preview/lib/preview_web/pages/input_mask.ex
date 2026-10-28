defmodule PreviewWeb.Pages.InputMask do
  use PreviewWeb.Page, title: "Input Mask", category: :forms, lineone: "forms-input-mask"

  @text "An input mask is a string of characters that indicates the format of valid input values. The cleave.js library is used for this purpose. See more on Github and to the code example below."

  @select "form-select border border-slate-300 bg-white px-3 py-2 pr-9 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"

  def mount(socket), do: assign(socket, thousands: "thousand", amount: nil)

  def handle_event("numeral", %{"style" => style} = params, socket) do
    {:noreply, assign(socket, thousands: style, amount: params["amount"])}
  end

  def render(assigns) do
    assigns = assign(assigns, text: @text, select: @select)

    ~H"""
    <.example title="Input Mask" text={@text} class="mt-5 max-w-xl">
      <.input
        id="inputmask1"
        name="prefix"
        label="With Prefix:"
        placeholder="Username"
        mask="blocks"
        mask_options={%{prefix: "Prefix", delimiter: "-", blocks: [6, 4, 4, 7]}}
      />
    </.example>
    <.example title="Delimiters Formatting" text={@text} class="mt-5 max-w-xl">
      <.input
        id="inputmask2"
        name="delimiters"
        label="With Delimiters Formatting:"
        placeholder="xxx.xx_xxx-xxx"
        mask="blocks"
        mask_options={%{delimiters: [".", "_", "-"], blocks: [3, 2, 3, 3], uppercase: true}}
      />
    </.example>
    <.example title="Credit Card" text={@text} class="mt-5 max-w-xl">
      <.input
        id="inputmask3"
        name="card"
        label="Enter Credit Card:"
        placeholder="xxxx xxxx xxxx xxxx"
        mask="credit_card"
      />
    </.example>
    <.example title="DateTime Formatting" text={@text} class="mt-5 max-w-xl space-y-4">
      <.input
        id="inputmask4"
        name="date"
        label="Date:"
        placeholder="Enter Date"
        mask="date"
        mask_options={%{pattern: ["m", "d", "Y"], delimiter: "-"}}
      />
      <.input
        id="inputmask5"
        name="time"
        label="Time:"
        placeholder="Enter Time"
        mask="time"
        mask_options={%{pattern: ["h", "m", "s"]}}
      />
    </.example>
    <.example title="Phone Formatting" text={@text} class="mt-5 max-w-xl">
      <.input_group label="Phone Number:">
        <.input_group_addon>US (+1)</.input_group_addon>
        <.input id="inputmask6" name="phone" placeholder="Enter Phone" mask="phone" />
      </.input_group>
    </.example>
    <.example
      title="Phone input"
      text="ISO codes in the button and the rows; `flags` brings the emoji back."
      class="mt-5 grid max-w-xl gap-4"
    >
      <.phone_input name="phone_iso" label="Phone number" value="+5571987654321" clearable />
      <.phone_input name="phone_flags" label="With flags" country="PT" flags />
    </.example>
    <.example title="Numeral Formatting" text={@text} class="mt-5 max-w-xl">
      <form id="numeral-form" phx-change="numeral">
        <.input_group shape="pill">
          <select id="maskUpdate" name="style" class={@select}>
            <option value="thousand" selected={@thousands == "thousand"}>Thousands</option>
            <option value="lakh" selected={@thousands == "lakh"}>Indian lakh</option>
            <option value="wan" selected={@thousands == "wan"}>Chinese wan</option>
          </select>
          <.input
            id="inputmask7"
            name="amount"
            value={@amount}
            placeholder="Enter Phone"
            mask="numeral"
            mask_submit="raw"
            mask_options={%{thousands: @thousands}}
          />
        </.input_group>
      </form>
      <p id="numeral-raw" class="mt-2 text-xs-plus text-slate-400 dark:text-navy-300">
        Submitted value: {@amount || "—"}
      </p>
    </.example>
    """
  end
end
