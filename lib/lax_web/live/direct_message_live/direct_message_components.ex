defmodule LaxWeb.DirectMessageLive.Components do
  alias Lax.Messages.Message
  use LaxWeb, :html

  import LaxWeb.UserLive.Components

  attr :class, :string, default: nil
  slot :inner_block

  def notice(assigns) do
    ~H"""
    <div class={["relative flex bg-zinc-900 border border-zinc-700 rounded p-2", @class]}>
      <span class="text-xs text-zinc-500">
        <%= render_slot(@inner_block) %>
      </span>
    </div>
    """
  end

  slot :inner_block

  def direct_message_list(assigns) do
    ~H"""
    <div class="flex-1 overflow-y-scroll no-scrollbar">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :current_user, Lax.Users.User
  attr :users, :list, required: true
  attr :latest_message, Lax.Messages.Message, required: true
  attr :selected, :boolean, default: false
  attr :online_fun, :any, required: true
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
          <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:md} class="mt-1" />
          <div class="flex-1 text-left">
            <.intersperse :let={user} enum={@users}>
              <:separator><span class="text-zinc-400">,</span></:separator>
              <.username user={user} />
            </.intersperse>
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
