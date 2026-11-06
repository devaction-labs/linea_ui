defmodule LineaUI.Components.Chip do
  @moduledoc """
  The canvas chip: a small grey pill for an applied filter or a selected person, with an optional
  avatar and a plain x that removes it.

      <.chip label="Situação: Aprovação" on_remove={JS.hide(to: "#c1")} id="c1" />
      <.chip avatar="Marina Costa" avatar_color="#8a5cd6" on_remove="remove_person" id="p-1">
        Marina Costa
      </.chip>
      <.chip label="Matriz" />

  Without `on_remove` it is read only (no x). An event name in `on_remove` is pushed with
  `%{"id" => id}`; a `JS` command runs as is.
  """

  use LineaUI.Component
  import LineaUI.Components.Avatar, only: [avatar: 1]

  @doc """
  Renders a chip, with `label` or the inner block as its text.

      <.chip label="Vendedor: Rafael" on_remove="clear_seller" />
  """
  attr(:label, :string, default: nil, doc: "The text; the inner block replaces it when given.")

  attr(:avatar, :string,
    default: nil,
    doc: "A person's name: draws a 24px avatar with its initials before the text."
  )

  attr(:avatar_color, :string,
    default: nil,
    doc: "A CSS color for the avatar's background; without it the avatar takes one from the name."
  )

  attr(:avatar_src, :string,
    default: nil,
    doc: "A picture for the avatar instead of the initials."
  )

  attr(:on_remove, :any,
    default: nil,
    doc:
      "An event name or a `JS` command: adds the x button. The event's payload is `%{\"id\" => id}`."
  )

  attr(:id, :string, default: nil)

  attr(:target, :any,
    default: nil,
    doc: "The `phx-target` of `on_remove` when it is an event name."
  )

  attr(:remove_label, :string, default: "Remove")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def chip(assigns) do
    ~H"""
    <span
      id={@id}
      class={
        merge([
          "sg-chip",
          (@avatar || @avatar_src) && "has-av",
          is_nil(@on_remove) && "static",
          @class
        ])
      }
      {@rest}
    >
      <.avatar
        :if={@avatar || @avatar_src}
        name={@avatar}
        alt={@avatar || "avatar"}
        src={@avatar_src}
        tint={@avatar_color}
        color={if @avatar_color, do: "neutral", else: "auto"}
        size="24"
        class="sg-chip-av"
      />
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        {@label}
      <% end %>
      <button
        :if={@on_remove}
        type="button"
        class="sg-chip-x"
        aria-label={@remove_label}
        phx-click={remove_js(@on_remove, @target, @id)}
      >
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
      </button>
    </span>
    """
  end

  defp remove_js(%JS{} = js, _target, _id), do: js
  defp remove_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp remove_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})
end
