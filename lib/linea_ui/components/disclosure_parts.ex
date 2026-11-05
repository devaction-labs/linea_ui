defmodule LineaUI.Components.DisclosureParts do
  @moduledoc """
  An accordion as parts (named disclosure so they do not clash with `accordion/1`): item, toggle, title, content and wrapper. They carry the `data-kt-accordion-*` attributes
  a page script can look for, so a page that loads it can open and close them.

      <div data-kt-accordion="true">
        <.disclosure_item>
          <.disclosure_toggle target="#q1" aria-controls="q1">
            <.disclosure_title>What is it?</.disclosure_title>
          </.disclosure_toggle>
          <.disclosure_content id="q1">
            <.disclosure_wrapper>An answer.</.disclosure_wrapper>
          </.disclosure_content>
        </.disclosure_item>
      </div>

  Use `accordion/1` for an accordion that opens and closes by itself.
  """

  use LineaUI.Component

  @doc "One section; the line under it is dropped for the last."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure_item(assigns) do
    ~H"""
    <div
      class={merge(["border-b border-slate-200 last:border-b-0 dark:border-navy-450", @class])}
      data-kt-accordion-item="true"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The button that opens the content `target` (a selector such as `#q1`)."
  attr :target, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure_toggle(assigns) do
    ~H"""
    <button
      type="button"
      class={
        merge([
          "flex w-full cursor-pointer items-center justify-between gap-2.5 py-4 text-start",
          @class
        ])
      }
      data-kt-accordion-toggle={@target}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The heading text of a toggle."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure_title(assigns) do
    ~H"""
    <span class={merge(["text-base font-medium text-slate-900 dark:text-white", @class])} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The part that is shown or hidden; it starts hidden."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure_content(assigns) do
    ~H"""
    <div class={merge(["hidden overflow-hidden transition-[height]", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Padding and text size of what is inside the content."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure_wrapper(assigns) do
    ~H"""
    <div class={merge(["pb-4 text-base text-slate-900 dark:text-navy-50", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
