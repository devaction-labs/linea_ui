defmodule LineaUI.Components.PlainTable do
  @moduledoc """
  A bare table: a `<table>` whose rows and cells are plain tags, styled by the table itself.

      <.table_plain border>
        <thead><tr><th>Name</th><th>Role</th></tr></thead>
        <tbody><tr><td>Ana</td><td>Admin</td></tr></tbody>
      </.table_plain>

  Use `table/1` for a table that takes columns and rows as data.
  """

  use LineaUI.Component

  @doc "A table styled through its tags. `border` draws a line between the columns; `highlight` shades the row under the pointer."
  attr :border, :boolean, default: false
  attr :highlight, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def table_plain(assigns) do
    ~H"""
    <table
      class={
        merge([
          "table-plain",
          @border && "table-plain-border",
          @highlight && "table-plain-highlight",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </table>
    """
  end
end
