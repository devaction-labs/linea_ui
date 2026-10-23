defmodule PreviewWeb.Pages.InputText do
  use PreviewWeb.Page, title: "Input Text", category: :forms, lineone: "forms-input-text"

  def mount(socket) do
    assign(socket, form: to_form(%{}, as: :account))
  end

  def handle_event("validate", %{"account" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :account, errors: errors(params)))}
  end

  def handle_event("save", %{"account" => params}, socket) do
    {:noreply,
     assign(socket, form: to_form(params, as: :account, errors: errors(params), action: :insert))}
  end

  defp errors(params) do
    case String.length(Map.get(params, "username", "")) do
      0 -> [username: {"Username can't be blank", []}]
      n when n < 3 -> [username: {"Username is invalid", []}]
      _ -> []
    end
  end

  def render(assigns) do
    ~H"""
    <.example
      title="Basic Input Text"
      text={
        ~s(The input element with a type attribute whose value is "text" represents a one-line plain text edit control for the input element’s value. Check out code for detail of usage.)
      }
      class="mt-5 max-w-xl"
    >
      <.input name="basic" placeholder="Username" />
    </.example>
    <.example
      title="Label Text"
      text="The label represents a caption for an item in a user interface. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input name="label" label="Choose Username:" placeholder="Username" />
    </.example>
    <.example
      title="Helper Text"
      text="Helper text conveys additional guidance about the input field, such as how it will be used. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input name="helper" placeholder="Username" help="This is a help text" />
    </.example>
    <.example
      title="Rounded Input"
      text="Input text can have a rounded-sm shape. To do this, you should use the rounded-full utility. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input name="rounded" shape="pill" placeholder="Username" />
    </.example>
    <.example
      title="Filled Input"
      text="Inputs can be filled. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input name="filled" variant="filled" placeholder="Username" />
    </.example>
    <.example
      title="Input Size"
      text="Input text can have various sizes. Check out code for detail of usage."
      class="mt-5 max-w-xl space-y-4"
    >
      <label :for={size <- ~w(sm md lg)} class="block">
        <.input name={"size-#{size}"} size={size} shape="pill" placeholder="Username" />
      </label>
    </.example>
    <.example
      title="Input Dataset"
      text="A datalist with pre-defined options (connected to an <input> element): Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input
        id="browser"
        name="browser"
        placeholder="Choose browser"
        options={["Google Chrome", "Edge", "Firefox", "Safari", "Opera"]}
      />
    </.example>
    <.example
      title="Disabled Text Input"
      text="Disabled text input have their own style when disabled. Check out code for detail of usage."
      class="mt-5 max-w-xl"
    >
      <.input name="disabled" placeholder="Disabled" disabled help="This is a disabled input text" />
    </.example>
    <.example
      title="Input Validation"
      text="You can validate the input text value using any validation libraries. Check out code for detail of usage."
      class="mt-5 max-w-xl space-y-4"
    >
      <.input
        name="valid"
        value="Some Value"
        placeholder="Username"
        state="success"
        help="Username is valid"
      />
      <.input
        name="invalid"
        value="Some Value"
        placeholder="Username"
        state="error"
        help="Username is invalid"
      />
    </.example>
    <.example
      id="live-validation"
      title="Live Validation"
      text="A real form: the field shows its error once you have typed in it, the way LiveView's used_input? decides."
      class="mt-5 max-w-xl"
    >
      <.form for={@form} id="account-form" phx-change="validate" phx-submit="save" class="space-y-4">
        <.input
          field={@form[:username]}
          label="Username"
          placeholder="At least 3 characters"
          phx-debounce="200"
        />
        <.button type="submit" color="primary">Save</.button>
      </.form>
    </.example>
    """
  end
end
