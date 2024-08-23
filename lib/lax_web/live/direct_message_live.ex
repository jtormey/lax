defmodule LaxWeb.DirectMessageLive do
  use LaxWeb, {:live_view, layout: :chat}

  alias Lax.Chat
  alias Lax.Messages.Message
  alias Lax.Users
  alias LaxWeb.DirectMessageLive.NewDirectMessageLive

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
            online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
            latest_message={message}
            selected={Chat.current?(@chat, message.channel)}
            phx-click={JS.patch(~p"/direct-messages/#{message.channel}")}
          />
        </.direct_message_list>
      </:sidebar>

      <.render_action :if={@current_user} {assigns} />

      <:right_sidebar
        :if={@user_profile}
        resize_event="resize_profile"
        width={profile_sidebar_width(@current_user)}
        min_width={300}
        max_width={700}
      >
        <.user_profile_sidebar
          user={@user_profile}
          online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
          on_cancel={JS.patch(~p"/direct-messages/#{@chat.current_channel}")}
        />
      </:right_sidebar>
    </.container>
    """
  end

  def render_action(%{live_action: :new} = assigns) do
    ~H"""
    <%= live_render(
      @socket,
      NewDirectMessageLive,
      id: "new_direct_message",
      session: %{
        "initial_user_ids" => @initial_user_ids
      },
      container: {:div, class: "flex flex-1 flex-col"}
    ) %>
    """
  end

  def render_action(%{live_action: :show} = assigns) do
    ~H"""
    <.chat_header channel={@chat.current_channel} users_fun={&Chat.direct_message_users(@chat, &1)} />

    <.chat>
      <.message
        :for={message <- group_messages(@chat.messages)}
        user={message.sent_by_user}
        user_detail_patch={
          ~p"/direct-messages/#{@chat.current_channel}?profile=#{message.sent_by_user}"
        }
        online={LaxWeb.Presence.Live.online?(assigns, message.sent_by_user)}
        time={Message.show_time(message, @current_user && @current_user.time_zone)}
        text={message.text}
        compact={message.compact}
        on_delete={
          @current_user && @current_user.id == message.sent_by_user_id &&
            JS.push("delete_message", value: %{id: message.id})
        }
      />
    </.chat>

    <.live_component
      id={"chat_component_#{@chat.current_channel.id}"}
      module={LaxWeb.ChatLive.ChannelChatComponent}
      chat={@chat}
    />
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :direct_messages)
     |> assign(:chat, Chat.load(socket.assigns.current_user))
     |> LaxWeb.Presence.Live.track_online_users()}
  end

  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> apply_chat_params(params)
     |> apply_profile_params(params)
     |> apply_initial_user_ids_params(params)}
  end

  def apply_chat_params(socket, %{"id" => channel_id}) do
    socket
    |> update(:chat, &Chat.select_channel(&1, channel_id))
    |> put_page_title()
  end

  def apply_chat_params(socket, _params) do
    socket
    |> update(:chat, &Chat.select_channel(&1, nil))
    |> assign(:page_title, "New message")
  end

  def apply_profile_params(socket, %{"profile" => user_id}) do
    assign(socket, :user_profile, Users.get_user!(user_id))
  end

  def apply_profile_params(socket, _params) do
    assign(socket, :user_profile, nil)
  end

  def apply_initial_user_ids_params(socket, %{"to_user" => user_id}) do
    assign(socket, :initial_user_ids, [user_id])
  end

  def apply_initial_user_ids_params(socket, _params) do
    assign(socket, :initial_user_ids, [])
  end

  def handle_event("resize", %{"width" => width}, socket) do
    if user = socket.assigns.current_user do
      {:ok, user} = Users.update_user_ui_settings(user, %{direct_messages_sidebar_width: width})
      {:noreply, assign(socket, :current_user, user)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("resize_profile", %{"width" => width}, socket) do
    if user = socket.assigns.current_user do
      {:ok, user} = Users.update_user_ui_settings(user, %{profile_sidebar_width: width})
      {:noreply, assign(socket, :current_user, user)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_message", %{"id" => message_id}, socket) do
    {:noreply, update(socket, :chat, &Chat.delete_message(&1, message_id))}
  end

  def handle_info({NewDirectMessageLive, {:create_direct_message, channel}}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> push_patch(to: ~p"/direct-messages/#{channel}")}
  end

  def handle_info({Lax.Channels, {:new_channel, _channel}}, socket) do
    {:noreply, update(socket, :chat, &Chat.reload_channels(&1))}
  end

  def handle_info({Lax.Messages, {:sent_message, message}}, socket) do
    {:noreply, update(socket, :chat, &Chat.receive_sent_message(&1, message))}
  end

  def handle_info({Lax.Messages, {:deleted_message, channel_message_ids}}, socket) do
    {:noreply, update(socket, :chat, &Chat.receive_deleted_message(&1, channel_message_ids))}
  end

  ## Helpers

  def sidebar_width(nil), do: 500
  def sidebar_width(current_user), do: current_user.ui_settings.direct_messages_sidebar_width

  def profile_sidebar_width(nil), do: 500
  def profile_sidebar_width(current_user), do: current_user.ui_settings.profile_sidebar_width
end
