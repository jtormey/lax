defmodule LaxWeb.DirectMessageLive.Components do
  alias Lax.Messages.Message
  use LaxWeb, :html

  import LaxWeb.UserLive.Components

  def empty_state(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center">
      <span class="text-xl text-zinc-500 font-semibold">
        Select a direct message to chat.
      </span>
    </div>
    """
  end

  slot :inner_block

  def direct_message_list(assigns) do
    ~H"""
    <div class="flex-1 overflow-y-scroll">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :current_user, Lax.Users.User
  attr :users, :list, required: true
  attr :latest_message, Lax.Messages.Message, required: true
  attr :selected, :boolean, default: false
  attr :rest, :global, include: ~w(phx-click phx-target)

  def direct_message_item_row(assigns) do
    ~H"""
    <button
      class={[
        "w-full",
        if(@selected, do: "bg-zinc-800", else: "hover:bg-zinc-800")
      ]}
      {@rest}
    >
      <div class="flex p-4 border-b border-zinc-700">
        <div class="relative flex-1 flex gap-4">
          <.user_profile user={hd(@users)} size={:md} class="mt-1" />
          <div class="flex-1 text-left">
            <div>
              <.intersperse :let={user} enum={@users}>
                <:separator>,</:separator>
                <.username user={user} />
              </.intersperse>
            </div>
            <div>
              <div class="absolute top-0 right-0">
                <span class="text-xs text-zinc-400">
                  <%= Message.show_time(@latest_message, @current_user && @current_user.time_zone) %>
                </span>
              </div>
              <span class="text-sm text-zinc-400 line-clamp-2">
                <%= @latest_message.sent_by_user.username %>: <%= @latest_message.text %>
              </span>
            </div>
          </div>
        </div>
      </div>
    </button>
    """
  end
end
