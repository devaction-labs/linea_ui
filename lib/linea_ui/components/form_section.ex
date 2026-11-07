defmodule LineaUI.Components.FormSection do
  @moduledoc """
  The canvas form section: a group of fields under a small title, laid out in a grid.

      <.form_section title="Contato">
        <.input field={@form[:email]} label="E-mail" />
        <.input field={@form[:phone]} label="Telefone" />
      </.form_section>

      <.form_section title="Endereço" description="Usado na NF-e" layout="aside">
        <.input field={@form[:zip]} label="CEP" />
        <.input field={@form[:number]} label="Número" />
      </.form_section>

  `stacked` (the default) puts the 13px title over the fields and closes the section with a line
  (`divider={false}` drops it); `aside` puts the title and its description in a 200px column at
  the left of the fields. The fields go in `columns` columns (two by default), one column on a
  narrow screen. The `:action` slot sits at the right of a stacked title.
  """

  use LineaUI.Component

  @doc """
  Renders a form section; the inner block is its fields.
  """
  attr(:title, :string, required: true, doc: "The section's title.")
  attr(:description, :string, default: nil, doc: "A line under the title.")

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked aside),
    doc: "`stacked`: the title over the fields; `aside`: the title in a column at their left."
  )

  attr(:columns, :integer, default: 2, values: [1, 2, 3], doc: "Columns of the fields' grid.")

  attr(:divider, :boolean,
    default: nil,
    doc: "A line under the section; by default on for `stacked`, off for `aside`."
  )

  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:action, doc: "At the right of a stacked title (a link, a toggle).")

  def form_section(%{layout: "aside"} = assigns) do
    ~H"""
    <section
      id={@id}
      class={merge(["lc-fs aside", @divider == true && "divider", @class])}
      aria-labelledby={@id && "#{@id}-title"}
      {@rest}
    >
      <div class="lc-fs-head">
        <b id={@id && "#{@id}-title"} class="lc-fs-name">{@title}</b>
        <span :if={@description} class="lc-fs-desc">{@description}</span>
      </div>
      <div class={["lc-fs-grid", "c#{@columns}"]}>{render_slot(@inner_block)}</div>
    </section>
    """
  end

  def form_section(assigns) do
    ~H"""
    <section
      id={@id}
      class={merge(["lc-fs stacked", @divider != false && "divider", @class])}
      aria-labelledby={@id && "#{@id}-title"}
      {@rest}
    >
      <h4 id={@id && "#{@id}-title"} class="lc-fs-title">
        {@title}{render_slot(@action)}
      </h4>
      <p :if={@description} class="lc-fs-desc">{@description}</p>
      <div class={["lc-fs-grid", "c#{@columns}"]}>{render_slot(@inner_block)}</div>
    </section>
    """
  end
end
