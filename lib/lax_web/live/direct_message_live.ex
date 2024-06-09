defmodule LaxWeb.DirectMessageLive do
  use LaxWeb, {:live_view, layout: :chat}

  alias Lax.Chat
  alias Lax.Messages
  alias Lax.Messages.Message
  alias Lax.Users

  import LaxWeb.ChatLive.Components
  import LaxWeb.DirectMessageLive.Components

  def render(assigns) do
    ~H"""
    <.container
      sidebar_width={sidebar_width(@current_user)}
      sidebar_min_width={288}
      sidebar_max_width={1024}
    >
      <:sidebar>
        <.sidebar_header title="Direct messages">
          <:actions :if={@current_user}>
            <.icon_button icon="hero-plus-mini" phx-click={JS.patch(~p"/direct-messages")} />
          </:actions>
        </.sidebar_header>

        <.notice :if={!@current_user} class="mx-4">
          Sign in to use the direct messaging feature.
        </.notice>

        <.direct_message_list>
          <.direct_message_item_row
            :for={message <- @chat.latest_message_in_direct_messages}
            current_user={@current_user}
            users={Chat.direct_message_users(@chat, message.channel)}
            latest_message={message}
            selected={Chat.current?(@chat, message.channel)}
            phx-click={JS.patch(~p"/direct-messages/#{message.channel}")}
          />
        </.direct_message_list>
      </:sidebar>

      <.render_action :if={@current_user} {assigns} />
    </.container>
    """
  end

  def render_action(%{live_action: :new} = assigns) do
    ~H"""
    <.live_component
      id="new_direct_message"
      module={__MODULE__.NewDirectMessageComponent}
      current_user={@current_user}
    />
    """
  end

  def render_action(%{live_action: :show} = assigns) do
    ~H"""
    <.chat_header channel={@chat.current_channel} users_fun={&Chat.direct_message_users(@chat, &1)} />

    <.chat>
      <.message
        :for={message <- group_messages(@chat.messages)}
        user={message.sent_by_user}
        time={Message.show_time(message, @current_user && @current_user.time_zone)}
        text={message.text}
        compact={message.compact}
        on_delete={
          @current_user && @current_user.id == message.sent_by_user_id &&
            JS.push("delete_message", value: %{id: message.id})
        }
      />
    </.chat>

    <.live_component id="chat_component" module={LaxWeb.ChatLive.ChannelChatComponent} chat={@chat} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :direct_messages)
     |> assign(:chat, Chat.load(socket.assigns.current_user))}
  end

  def handle_params(%{"id" => channel_id}, _uri, socket) do
    {:noreply, update(socket, :chat, &Chat.select_channel(&1, channel_id))}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, update(socket, :chat, &Chat.select_channel(&1, nil))}
  end

  def handle_event("resize", %{"width" => width}, socket) do
    if user = socket.assigns.current_user do
      {:ok, user} = Users.update_user_ui_settings(user, %{direct_messages_sidebar_width: width})
      {:noreply, assign(socket, :current_user, user)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_message", %{"id" => message_id}, socket) do
    Messages.delete!(message_id, socket.assigns.current_user)
    {:noreply, update(socket, :chat, &Chat.reload_messages(&1))}
  end

  def handle_info({Lax.Channels, {:new_channel, _channel}}, socket) do
    {:noreply, update(socket, :chat, &Chat.reload_channels(&1))}
  end

  def handle_info({Lax.Messages, {:new_message, message}}, socket) do
    {:noreply, update(socket, :chat, &Chat.receive_message(&1, message))}
  end

  ## Helpers

  def sidebar_width(nil), do: 500
  def sidebar_width(current_user), do: current_user.ui_settings.direct_messages_sidebar_width
end
