defmodule LaxWeb.ChatLiveComponents do
  use LaxWeb, :html

  attr :sidebar_width, :integer, required: true
  slot :sidebar, required: true
  slot :inner_block, required: true

  def container(assigns) do
    ~H"""
    <div class="flex h-full">
      <div
        id="sidebar_resizeable"
        phx-hook="ResizeContainer"
        style={"width:#{@sidebar_width}px;"}
        class="resize-container-right border-r border-zinc-700 flex flex-col"
      >
        <%= render_slot(@sidebar) %>
      </div>
      <div class="bg-zinc-900 flex-1 flex flex-col">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def sidebar_header(assigns) do
    ~H"""
    <div class="p-4">
      <.header>Workspace</.header>
    </div>
    """
  end

  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="flex-1 overflow-y-scroll py-4 px-2">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, required: true

  def sidebar_section(assigns) do
    ~H"""
    <div class="mb-4">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :actions, default: []
  slot :inner_block, required: true

  def sidebar_subheader(assigns) do
    ~H"""
    <div class="flex items-center justify-between rounded leading-none px-2 py-1">
      <span class="text-sm font-semibold text-zinc-300 truncate">
        <%= render_slot(@inner_block) %>
      </span>
      <%= render_slot(@actions) %>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :selected, :boolean, default: false
  attr :active, :boolean, default: false
  attr :rest, :global, include: ~w(phx-click phx-target)

  def channel_item(assigns) do
    assigns = assign(assigns, :text_class, text_class(assigns))

    ~H"""
    <.item_button {assigns}>
      <.icon name="hero-hashtag" class={["size-4", @text_class]} />
      <span class={["text-sm truncate", @text_class]}><%= @name %></span>
    </.item_button>
    """
  end

  attr :username, :string, required: true
  attr :selected, :boolean, default: false
  attr :active, :boolean, default: false
  attr :online, :boolean, default: false
  attr :unread_count, :integer, default: 0
  attr :rest, :global, include: ~w(phx-click phx-target)

  def dm_item(assigns) do
    assigns = assign(assigns, :text_class, text_class(assigns))

    ~H"""
    <.item_button {assigns}>
      <div class="relative bg-red-100 rounded size-4">
        <div class={[
          "absolute -bottom-px -right-0.5 rounded-full size-1.5 ring-2 ring-zinc-950",
          @online && "bg-emerald-500",
          !@online && "border border-zinc-500 bg-zinc-950"
        ]} />
      </div>
      <span class={["text-sm truncate", @text_class]}><%= @username %></span>
      <div
        :if={@unread_count > 0}
        class="absolute right-2 flex items-center justify-center bg-rose-500 size-5 rounded"
      >
        <span class="text-xs text-white font-semibold"><%= @unread_count %></span>
      </div>
    </.item_button>
    """
  end

  defp item_button(assigns) do
    ~H"""
    <button
      class={[
        "relative flex items-center gap-2 w-full rounded leading-none px-2 py-1",
        if(@selected, do: "bg-zinc-600", else: "hover:bg-zinc-800"),
        if(@active, do: "font-bold")
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp text_class(assigns) do
    if assigns.selected or assigns.active do
      "text-white"
    else
      "text-zinc-400 group-hover:text-white"
    end
  end

  attr :channel, :string, required: true

  def chat_header(assigns) do
    ~H"""
    <div class="flex gap-2 border-b border-zinc-700 p-4">
      <.header>
        <.icon name="hero-hashtag" class="text-white size-5" /> <%= @channel %>
      </.header>
    </div>
    """
  end

  slot :inner_block, required: true

  def chat(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col-reverse py-4 overflow-y-scroll">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :username, :string, required: true
  attr :time, :string, required: true
  attr :message, :string, required: true

  def message(assigns) do
    ~H"""
    <div class="flex gap-2 hover:bg-zinc-800 px-4 py-2">
      <div class="size-8 bg-red-100 rounded-lg mt-1"></div>
      <div>
        <div class="space-x-1 leading-none">
          <span class="text-sm text-white font-bold">
            <%= @username %>
          </span>
          <span class="text-xs text-zinc-400">
            <%= @time %>
          </span>
        </div>
        <div>
          <p class="text-sm text-zinc-300">
            <%= @message %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :channel, :string, required: true
  attr :rest, :global, include: ~w(phx-change phx-submit)

  def chat_form(assigns) do
    ~H"""
    <div class="px-4 pb-4">
      <.form for={@form} class="-mt-2" {@rest}>
        <.input
          type="textarea"
          phx-hook="ControlTextarea"
          field={@form[:message]}
          placeholder={"Message ##{@channel}"}
          autofocus
        >
          <div class="flex items-center p-1">
            <div class="flex-1" />
            <.chat_submit_button disabled={@form[:message].value in [nil, ""]} />
          </div>
        </.input>
      </.form>
    </div>
    """
  end

  attr :disabled, :boolean, required: true

  def chat_submit_button(assigns) do
    ~H"""
    <button
      type="submit"
      class="flex bg-emerald-600 group disabled:bg-zinc-800 rounded py-1 px-4"
      disabled={@disabled}
    >
      <.icon name="hero-paper-airplane-solid" class="size-4 text-white group-disabled:text-zinc-500" />
    </button>
    """
  end
end
