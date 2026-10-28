defmodule PreviewWeb.Pages.InputGroup do
  use PreviewWeb.Page, title: "Input Group", category: :forms, lineone: "forms-input-group"

  import PreviewWeb.FormIcons

  @text "Easily extend form controls by adding text, buttons, or button groups on either side of textual inputs, custom selects, and custom file inputs. Check out code for detail of usage."

  @select "form-select border border-slate-300 bg-white px-3 py-2 pr-9 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"

  def render(assigns) do
    assigns = assign(assigns, text: @text, select: @select)

    ~H"""
    <.example title="Input Group" text={@text} class="mt-5 max-w-xl space-y-4">
      <.input_group label="Prepend Addon:">
        <.input_group_addon><span class="-mt-1 block">@</span></.input_group_addon>
        <.input name="prepend" placeholder="Username" />
      </.input_group>
      <.input_group label="Append Addon:">
        <.input name="append" placeholder="Username" />
        <.input_group_addon>@site.com</.input_group_addon>
      </.input_group>
      <.input_group label="Between input:" class="mt-1">
        <.input_group_addon>$</.input_group_addon>
        <.input name="between" placeholder="Enter Price" />
        <.input_group_addon>.00</.input_group_addon>
      </.input_group>
    </.example>
    <.example
      title="Filled Addon"
      text="Input addon can be filled. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input_group label="Between input:" class="mt-1">
        <.input_group_addon variant="filled">$</.input_group_addon>
        <.input name="filled" placeholder="Enter price" />
        <.input_group_addon variant="filled">.00</.input_group_addon>
      </.input_group>
    </.example>
    <.example
      title="Merged Addon"
      text="Input addon can be merged. Check out code for detail of usage."
      class="mt-5 max-w-xl space-y-4"
    >
      <.input name="merged-search" placeholder="Search here...">
        <:prefix><.search_icon /></:prefix>
      </.input>
      <.input name="merged-password" placeholder="Password">
        <:suffix>
          <svg fill="currentColor" class="size-4.5" viewBox="0 0 20 20">
            <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
            <path
              fill-rule="evenodd"
              d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
              clip-rule="evenodd"
            />
          </svg>
        </:suffix>
      </.input>
      <.input name="merged-loading" placeholder="Search here...">
        <:prefix><.search_icon /></:prefix>
        <:suffix>
          <span class="spinner size-5 animate-spin rounded-full border-2 border-slate-150 border-r-slate-400 dark:border-navy-500 dark:border-r-navy-300"></span>
        </:suffix>
      </.input>
    </.example>
    <.example title="More Examples" text={@text} class="mt-5 max-w-xl space-y-4">
      <.input_group>
        <.input name="user" placeholder="Username" />
        <.input_group_addon variant="filled"><span class="-mt-1 block">@</span></.input_group_addon>
        <.input name="server" placeholder="Server" />
      </.input_group>
      <.input_group shape="pill">
        <select class={@select}>
          <option>$</option>
          <option>£</option>
          <option>€</option>
        </select>
        <.input name="price" placeholder="Price" />
        <.button>Purchase</.button>
      </.input_group>
      <.input_group>
        <.input name="dropdown-search" placeholder="Search...">
          <:prefix>
            <.lineone_icon name="location" class="size-5 transition-colors duration-200" />
          </:prefix>
        </.input>
        <.button color="primary">Dropdown</.button>
      </.input_group>
    </.example>
    <.example
      title="Addon Sizes"
      text="The addon text follows the size of the inputs beside it."
      class="mt-5 max-w-xl space-y-4"
    >
      <.input_group>
        <.input_group_addon size="sm">@</.input_group_addon>
        <.input name="addon-sm" size="sm" placeholder="Username" />
        <.button size="sm" color="primary">Follow</.button>
      </.input_group>
      <.input_group>
        <.input_group_addon size="lg">@</.input_group_addon>
        <.input name="addon-lg" size="lg" placeholder="Username" />
        <.button size="lg" color="primary">Follow</.button>
      </.input_group>
    </.example>
    """
  end

  defp search_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-4.5 transition-colors duration-200"
      fill="currentColor"
      viewBox="0 0 24 24"
    >
      <path d="M3.316 13.781l.73-.171-.73.171zm0-5.457l.73.171-.73-.171zm15.473 0l.73-.171-.73.171zm0 5.457l.73.171-.73-.171zm-5.008 5.008l-.171-.73.171.73zm-5.457 0l-.171.73.171-.73zm0-15.473l-.171-.73.171.73zm5.457 0l.171-.73-.171.73zM20.47 21.53a.75.75 0 101.06-1.06l-1.06 1.06zM4.046 13.61a11.198 11.198 0 010-5.115l-1.46-.342a12.698 12.698 0 000 5.8l1.46-.343zm14.013-5.115a11.196 11.196 0 010 5.115l1.46.342a12.698 12.698 0 000-5.8l-1.46.343zm-4.45 9.564a11.196 11.196 0 01-5.114 0l-.342 1.46c1.907.448 3.892.448 5.8 0l-.343-1.46zM8.496 4.046a11.198 11.198 0 015.115 0l.342-1.46a12.698 12.698 0 00-5.8 0l.343 1.46zm0 14.013a5.97 5.97 0 01-4.45-4.45l-1.46.343a7.47 7.47 0 005.568 5.568l.342-1.46zm5.457 1.46a7.47 7.47 0 005.568-5.567l-1.46-.342a5.97 5.97 0 01-4.45 4.45l.342 1.46zM13.61 4.046a5.97 5.97 0 014.45 4.45l1.46-.343a7.47 7.47 0 00-5.568-5.567l-.342 1.46zm-5.457-1.46a7.47 7.47 0 00-5.567 5.567l1.46.342a5.97 5.97 0 014.45-4.45l-.343-1.46zm8.652 15.28l3.665 3.664 1.06-1.06-3.665-3.665-1.06 1.06z" />
    </svg>
    """
  end
end
