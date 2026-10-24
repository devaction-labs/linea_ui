defmodule PreviewWeb.Pages.FormLayout2 do
  use PreviewWeb.Page, title: "Form Layout 2", category: :forms, lineone: "forms-layout-2"

  import PreviewWeb.FormIcons

  @select "form-select w-full rounded-lg border border-slate-300 bg-white px-3 py-2 pr-9 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"

  @steps [
    {"layers", "Step 1", "General", true},
    {"list", "Step 2", "Description", false},
    {"truck", "Step 3", "Shipping", false},
    {"check", "Step 4", "Confirm", false}
  ]

  def render(assigns) do
    assigns = assign(assigns, select: @select, steps: @steps)

    ~H"""
    <div class="grid grid-cols-12 gap-4 sm:gap-5 lg:gap-6">
      <div class="col-span-12 grid lg:col-span-4 lg:place-items-center">
        <div>
          <ol class="steps is-vertical line-space [--size:2.75rem] [--line:.5rem]">
            <li
              :for={{{icon, step, title, current}, index} <- Enum.with_index(@steps)}
              class={[
                "step space-x-4 before:bg-slate-200 dark:before:bg-navy-500",
                index < 3 && "pb-12"
              ]}
            >
              <div class={[
                "step-header mask is-hexagon",
                current && "bg-primary text-white dark:bg-accent",
                !current && "bg-slate-200 text-slate-500 dark:bg-navy-500 dark:text-navy-100"
              ]}>
                <.lineone_icon name={icon} class="size-4.5" stroke="2" />
              </div>
              <div class="text-left">
                <p class="text-xs text-slate-400 dark:text-navy-300">{step}</p>
                <h3 class={[
                  "text-base font-medium",
                  current && "text-primary dark:text-accent-light"
                ]}>
                  {title}
                </h3>
              </div>
            </li>
          </ol>
        </div>
      </div>
      <div class="col-span-12 grid lg:col-span-8">
        <div class="card">
          <div class="border-b border-slate-200 p-4 dark:border-navy-500 sm:px-5">
            <div class="flex items-center space-x-2">
              <div class="flex size-7 items-center justify-center rounded-lg bg-primary/10 p-1 text-primary dark:bg-accent-light/10 dark:text-accent-light">
                <.lineone_icon name="layers" class="size-4" stroke="2" />
              </div>
              <h4 class="text-lg font-medium text-slate-700 dark:text-navy-100">General</h4>
            </div>
          </div>
          <div class="space-y-4 p-4 sm:p-5">
            <.input name="product" label="Product name" placeholder="Enter product name" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.field id="category" label="Category">
                <select id="category" name="category" class={@select}>
                  <option>Digital</option>
                  <option>Technology</option>
                  <option>Home</option>
                  <option>Other</option>
                </select>
              </.field>
              <div class="grid grid-cols-2 gap-4">
                <.input name="sku" label="SKU" placeholder="SKU" />
                <.input name="price" label="Price" placeholder="Price" mask="numeral" />
              </div>
            </div>
            <div>
              <span>Images</span>
              <label class="mt-1.5 mb-4 flex h-[76px] cursor-pointer items-center justify-center rounded-lg border-2 border-dashed border-slate-300 text-base text-slate-600 dark:border-navy-450 dark:text-navy-100">
                <input type="file" name="images" multiple class="sr-only" />
                <span>Drag & Drop your files or <span class="underline">Browse</span></span>
              </label>
            </div>
            <div class="flex justify-center space-x-2 pt-4">
              <.button class="space-x-2">
                <.lineone_icon name="prev" class="size-5" /><span>Prev</span>
              </.button>
              <.button color="primary" class="space-x-2">
                <span>Next</span><.lineone_icon name="next" class="size-5" />
              </.button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
