defmodule LaxWeb.ChatLiveComponents do
  use LaxWeb, :html

  attr :sidebar_width, :integer, required: true
  slot :sidebar, required: true
  slot :inner_block, required: true

  def container(assigns) do
    ~H"""
    <div class="flex h-full">
      <div style={"width:#{@sidebar_width}px;"} class="border-r border-zinc-700 flex flex-col">
        <%= render_slot(@sidebar) %>
      </div>
      <div>
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

  slot :actions, default: []
  slot :inner_block, required: true

  def chat_header(assigns) do
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
    text_class =
      if assigns.selected or assigns.active do
        "text-white"
      else
        "text-zinc-400 group-hover:text-white"
      end

    assigns = assign(assigns, :text_class, text_class)

    ~H"""
    <button
      class={[
        "flex items-center gap-2 w-full rounded leading-none px-2 py-1",
        if(@selected, do: "bg-zinc-600", else: "hover:bg-zinc-800"),
        if(@active, do: "font-bold")
      ]}
      {@rest}
    >
      <.icon name="hero-hashtag" class={["size-3", @text_class]} />
      <span class={["text-sm truncate", @text_class]}><%= @name %></span>
    </button>
    """
  end
end
