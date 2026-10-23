defmodule PreviewWeb.Pages.FormLayout4 do
  use PreviewWeb.Page, title: "Form Layout 4", category: :forms, lineone: "forms-layout-4"

  import PreviewWeb.FormIcons

  @select "form-select w-full rounded-lg border border-slate-300 bg-white px-3 py-2 pr-9 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"
  @caption "font-medium text-slate-600 dark:text-navy-100"

  def render(assigns) do
    assigns = assign(assigns, select: @select, caption: @caption)

    ~H"""
    <div class="flex flex-col items-center justify-between space-y-4 pb-5 sm:flex-row sm:space-y-0 lg:pb-6">
      <div class="flex items-center space-x-1">
        <.icon name="doc-plus" class="size-6" stroke="2" />
        <h2 class="text-xl font-medium text-slate-700 line-clamp-1 dark:text-navy-50">New Post</h2>
      </div>
      <div class="flex justify-center space-x-2">
        <.button variant="outline" class="min-w-[7rem] text-slate-700 dark:text-navy-100">
          Preview
        </.button>
        <.button color="primary" class="min-w-[7rem]">Save</.button>
      </div>
    </div>
    <div class="grid grid-cols-12 gap-4 sm:gap-5 lg:gap-6">
      <div class="col-span-12 lg:col-span-8">
        <div class="card">
          <div class="is-scrollbar-hidden overflow-x-auto">
            <div class="border-b-2 border-slate-150 dark:border-navy-500">
              <div class="-mb-0.5 flex">
                <.tab icon="layers" label="General" active />
                <.tab icon="tag" label="Meta Tags" />
                <.tab icon="bars" label="Keywords" />
              </div>
            </div>
          </div>
          <div class="space-y-5 p-4 sm:p-5">
            <.input name="title" label="Title" label_class={@caption} placeholder="Enter post title" />
            <.input
              name="caption"
              label="Caption"
              label_class={@caption}
              placeholder="Enter post caption"
            />
            <.textarea
              name="content"
              label="Post Content"
              label_class={@caption}
              rows={8}
              placeholder="Enter your content..."
            />
            <div>
              <span class={@caption}>Post Images</span>
              <label class="mt-1.5 flex h-[76px] cursor-pointer items-center justify-center rounded-lg border border-slate-300 bg-slate-100 text-slate-500 dark:border-navy-450 dark:bg-navy-600 dark:text-navy-200">
                <input type="file" name="images" multiple class="sr-only" />
                <span>Drag & Drop your files or <span class="underline">Browse</span></span>
              </label>
            </div>
          </div>
        </div>
      </div>
      <div class="col-span-12 lg:col-span-4">
        <div class="card space-y-5 p-4 sm:p-5">
          <.field id="postAuthor" label="Select Author" label_class={@caption}>
            <select id="postAuthor" name="author" class={@select}>
              <option value="">Select the author</option>
              <option>John Doe</option>
              <option>Emilie Watson</option>
              <option>Nancy Clarke</option>
            </select>
          </.field>
          <.field id="postCategory" label="Category" label_class={@caption}>
            <select id="postCategory" name="category" class={@select}>
              <option value="">Select the category</option>
              <option value="accessories">Accessories</option>
              <option value="digital">Digital</option>
              <option value="home">Home</option>
              <option value="technology">Technology</option>
            </select>
          </.field>
          <.input
            id="postTags"
            name="tags"
            label="Tags"
            label_class={@caption}
            placeholder="Enter Tags"
          />
          <.input
            id="postPublishDate"
            name="publish"
            type="date"
            label="Publish Date"
            label_class={@caption}
            placeholder="Choose date..."
          >
            <:prefix><.icon name="calendar" class="size-5 transition-colors duration-200" /></:prefix>
          </.input>
        </div>
      </div>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp tab(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "btn h-14 shrink-0 space-x-2 rounded-none border-b-2 px-4 font-medium sm:px-5",
        @active && "border-primary text-primary dark:border-accent dark:text-accent-light",
        !@active &&
          "border-transparent hover:text-slate-800 focus:text-slate-800 dark:hover:text-navy-100 dark:focus:text-navy-100"
      ]}
    >
      <.icon name={@icon} class="size-4.5" stroke="2" /><span>{@label}</span>
    </button>
    """
  end
end
