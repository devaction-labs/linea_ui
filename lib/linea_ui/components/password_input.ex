defmodule LineaUI.Components.PasswordInput do
  @moduledoc """
  A password field with the button that shows what was typed.

      <.password_input name="password" placeholder="Enter password" />

  It is an `input/1` of `type="password"` (every attr of `input/1` is taken) with an eye at the end. The button flips the
  type of the field between `password` and `text` with `Phoenix.LiveView.JS`, so it needs no hook, and its icon follows
  the type.
  """

  use LineaUI.Component

  import LineaUI.Components.Input, only: [input: 1]

  @doc """
  Renders the field and the eye.

      <.password_input field={@form[:password]} label="Password" />
  """
  attr :id, :string, default: nil, doc: "Defaults to the field id, `name`, or a generated one."
  attr :show_label, :string, default: "Show the password"
  attr :hide_label, :string, default: "Hide the password"
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(field name value label help errors placeholder disabled size variant state autocomplete required minlength maxlength form)

  def password_input(assigns) do
    assigns =
      assign(assigns, :id, assigns.id || assigns.rest[:id] || stable_id("password", assigns))

    ~H"""
    <div class={merge(["group/pw relative", @class])}>
      <.input type="password" id={@id} class="pe-10" {@rest} />
      <button
        type="button"
        aria-label={@show_label}
        aria-controls={@id}
        phx-click={JS.toggle_attribute({"type", "password", "text"}, to: "#" <> @id)}
        class="absolute end-1 bottom-0 flex h-10 w-8 items-center justify-center rounded-md text-slate-500 outline-none hover:text-slate-950 focus-visible:ring-2 focus-visible:ring-primary/50 dark:text-navy-300 dark:hover:text-navy-50"
      >
        <svg
          viewBox="0 0 24 24"
          class="size-4.5 group-has-[input[type=text]]/pw:hidden"
          fill="none"
          stroke="currentColor"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z" />
          <circle cx="12" cy="12" r="3" />
        </svg>
        <svg
          viewBox="0 0 24 24"
          class="hidden size-4.5 group-has-[input[type=text]]/pw:block"
          fill="none"
          stroke="currentColor"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="M3 3l18 18M10.6 6.2A9.6 9.6 0 0 1 12 6c6.4 0 10 6 10 6a17 17 0 0 1-3.2 3.9M6.6 7.6A17 17 0 0 0 2 12s3.6 6 10 6a9.7 9.7 0 0 0 4-.8M9.9 9.9a3 3 0 0 0 4.2 4.2" />
        </svg>
      </button>
    </div>
    """
  end
end
