defmodule LaxWeb.ChatLive.Components do
  alias Lax.Chat
  use LaxWeb, :html

  import LaxWeb.UserLive.Components

  attr :sidebar_width, :integer, required: true
  attr :sidebar_min_width, :integer, default: 128
  attr :sidebar_max_width, :integer, default: 512
  slot :sidebar, required: true
  slot :inner_block, required: true

  slot :right_sidebar do
    attr :resize_event, :string
    attr :width, :integer
    attr :min_width, :integer
    attr :max_width, :integer
  end

  def container(assigns) do
    ~H"""
    <div class="flex h-full">
      <div
        id="sidebar_resizeable"
        phx-hook="ResizeContainer"
        data-min-width={@sidebar_min_width}
        data-max-width={@sidebar_max_width}
        style={"width:#{@sidebar_width}px;"}
        class="resize-container resize-container-right border-r border-zinc-700 flex flex-col"
      >
        <%= render_slot(@sidebar) %>
      </div>
      <div class="bg-zinc-900 flex-1 flex flex-col">
        <%= render_slot(@inner_block) %>
      </div>
      <div
        :for={sidebar <- @right_sidebar}
        id="right_sidebar_resizeable"
        phx-hook="ResizeContainer"
        phx-resize={sidebar.resize_event}
        data-min-width={sidebar.min_width}
        data-max-width={sidebar.max_width}
        style={"width:#{sidebar.width}px;"}
        class="resize-container resize-container-left border-l border-zinc-700 flex flex-col"
      >
        <%= render_slot(sidebar) %>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :actions, default: []

  def sidebar_header(assigns) do
    ~H"""
    <div class="px-4 flex items-center justify-between">
      <div class="py-4">
        <.header><%= @title %></.header>
      </div>
      <%= render_slot(@actions) %>
    </div>
    """
  end

  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="flex-1 overflow-y-scroll no-scrollbar py-4 px-2">
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

  attr :on_click, JS, default: nil
  slot :actions, default: []
  slot :inner_block, required: true

  def sidebar_subheader(assigns) do
    ~H"""
    <div class="flex items-center justify-between rounded leading-none px-2 py-1">
      <span :if={!@on_click} class="text-sm font-semibold text-zinc-300 truncate">
        <%= render_slot(@inner_block) %>
      </span>
      <button
        :if={@on_click}
        phx-click={@on_click}
        class="text-sm font-semibold text-zinc-300 truncate rounded hover:bg-zinc-700 px-1 -ml-1"
      >
        <%= render_slot(@inner_block) %>
      </button>
      <%= render_slot(@actions) %>
    </div>
    """
  end

  attr :user, Lax.Users.User, required: true
  attr :online_fun, :any, required: true
  attr :on_cancel, JS, required: true

  def user_profile_sidebar(assigns) do
    ~H"""
    <button phx-click={@on_cancel} class="absolute top-2 right-3">
      <.icon name="hero-x-mark" class="size-4 text-white" />
    </button>

    <div class="pt-32 flex flex-col items-center">
      <.user_profile user={@user} online={@online_fun.(@user)} size={:xl} />
      <div class="mt-8">
        <.username user={@user} />
      </div>
      <div class="mt-4">
        <% local_time = DateTime.shift_zone!(DateTime.utc_now(), @user.time_zone) %>
        <% local_time_strftime = Calendar.strftime(local_time, "%-I:%M%P") %>
        <span class="text-xs text-zinc-200">
          Timezone: <%= @user.time_zone %> (<%= local_time_strftime %> local)
        </span>
      </div>
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
      <div class="w-4">
        <.icon name="hero-hashtag" class={["size-4", @text_class]} />
      </div>
      <span class={["text-sm truncate", @text_class]}><%= @name %></span>
    </.item_button>
    """
  end

  attr :users, :list, required: true
  attr :selected, :boolean, default: false
  attr :active, :boolean, default: false
  attr :online_fun, :any, required: true
  attr :unread_count, :integer, default: 0
  attr :rest, :global, include: ~w(phx-click phx-target)

  def direct_message_item(assigns) do
    assigns = assign(assigns, :text_class, text_class(assigns))

    ~H"""
    <.item_button {assigns}>
      <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:xs} />
      <div>
        <.intersperse :let={user} enum={@users}>
          <:separator><span class="text-zinc-400">,</span></:separator>
          <span class={["text-sm truncate", @text_class]}>
            <%= user.username %>
          </span>
        </.intersperse>
      </div>
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

  attr :channel, Lax.Channels.Channel, required: true
  attr :users_fun, :any

  def chat_header(%{channel: %{type: :channel}} = assigns) do
    ~H"""
    <div class="border-b border-zinc-700 px-4">
      <.header>
        <div class="flex gap-2 items-center">
          <.icon name="hero-hashtag" class="text-white size-5" />
          <div class="py-4">
            <%= @channel.name %>
          </div>
        </div>
      </.header>
    </div>
    """
  end

  def chat_header(%{channel: %{type: :direct_message}} = assigns) do
    ~H"""
    <div class="border-b border-zinc-700 px-4">
      <.header>
        <div class="flex gap-2 items-center">
          <.icon name="hero-at-symbol" class="text-white size-5" />
          <div class="py-4">
            <.intersperse :let={user} enum={@users_fun.(@channel)}>
              <:separator><span class="text-zinc-400">,</span></:separator>
              <%= user.username %>
            </.intersperse>
          </div>
        </div>
      </.header>
    </div>
    """
  end

  slot :inner_block, required: true

  def chat(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col-reverse py-4 overflow-y-scroll no-scrollbar">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :user, Lax.Users.User, required: true
  attr :user_detail_patch, :string
  attr :online, :boolean, required: true
  attr :time, :string, required: true
  attr :text, :string, required: true
  attr :compact, :boolean, required: true
  attr :on_delete, JS, default: nil

  def message(%{compact: true} = assigns) do
    ~H"""
    <div class="relative flex gap-2 hover:bg-zinc-800 px-4 py-1 group">
      <div class="w-8 flex items-start justify-end pt-0.5 invisible group-hover:visible">
        <span class="text-xs text-zinc-400">
          <%= @time %>
        </span>
      </div>
      <div class="flex-1">
        <p class="text-sm text-zinc-300 whitespace-pre-wrap"><%= @text %></p>
      </div>
      <div :if={@on_delete} class="absolute top-1 right-4 hidden group-hover:block">
        <.icon_button icon="hero-trash" phx-click={@on_delete} />
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class="relative flex gap-2 hover:bg-zinc-800 px-4 pt-2 pb-1 group">
      <.user_profile user={@user} size={:md} class="mt-1" online={@online} />
      <div class="flex-1">
        <div class="space-x-1 leading-none">
          <.link patch={@user_detail_patch}>
            <.username user={@user} />
          </.link>
          <span class="text-xs text-zinc-400">
            <%= @time %>
          </span>
        </div>
        <div class="flex-1">
          <p class="text-sm text-zinc-300 whitespace-pre-wrap"><%= @text %></p>
        </div>
      </div>
      <div :if={@on_delete} class="absolute top-1 right-4 hidden group-hover:block">
        <.icon_button icon="hero-trash" phx-click={@on_delete} />
      </div>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :placeholder, :string, required: true
  attr :rest, :global, include: ~w(phx-change phx-submit phx-target)

  def chat_form(assigns) do
    ~H"""
    <div class="relative px-4 pb-4">
      <.form for={@form} class="-mt-2" {@rest}>
        <.input
          type="textarea"
          phx-hook="ControlTextarea"
          field={@form[:text]}
          placeholder={@placeholder}
          autofocus
        >
          <div class="flex items-center p-1">
            <div class="flex-1" />
            <.chat_submit_button disabled={not @form.source.valid?} />
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

  ## Helpers

  def put_page_title(socket) do
    chat = socket.assigns.chat

    page_title =
      case chat.current_channel do
        nil ->
          "Channels"

        %{type: :channel} = channel ->
          "##{channel.name}"

        %{type: :direct_message} = channel ->
          "#{Enum.map_join(Chat.direct_message_users(chat, channel), ", ", &"@#{&1.username}")}"
      end

    assign(socket, :page_title, page_title)
  end

  def group_messages(messages) do
    messages
    |> Enum.chunk_by(& &1.sent_by_user_id)
    |> Enum.flat_map(fn chunk ->
      chunk
      |> Enum.map(&%{&1 | compact: true})
      |> List.update_at(-1, &%{&1 | compact: false})
    end)
  end
end
