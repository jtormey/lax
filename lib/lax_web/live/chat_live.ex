defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}
  use LaxNative, :live_view

  alias Lax.Chat
  alias Lax.Messages.Message
  alias Lax.Users
  alias LaxWeb.ChatLive.ChannelChatComponent
  alias LaxWeb.ChatLive.ChannelFormComponent
  alias LaxWeb.ChatLive.ManageChannelsComponent

  import LaxWeb.ChatLive.Components
  import LaxWeb.DirectMessageLive.Components

  def render(assigns) do
    ~H"""
    <.container sidebar_width={sidebar_width(@current_user)}>
      <:sidebar>
        <.sidebar_header title="Workspace" />
        <.sidebar>
          <.sidebar_section>
            <.sidebar_subheader on_click={@current_user && JS.push("show_manage_channels")}>
              Channels
              <:actions :if={@current_user}>
                <.icon_button icon="hero-plus" phx-click="show_new_channel" />
              </:actions>
            </.sidebar_subheader>
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              selected={Chat.current?(@chat, channel)}
              active={Chat.has_activity?(@chat, channel)}
              phx-click={JS.patch(~p"/chat/#{channel.id}")}
            />
          </.sidebar_section>

          <.sidebar_section>
            <.sidebar_subheader>
              Direct messages
              <:actions>
                <.icon_button icon="hero-plus" phx-click={JS.navigate(~p"/direct-messages")} />
              </:actions>
            </.sidebar_subheader>
            <.direct_message_item
              :for={channel <- @chat.direct_messages}
              users={Chat.direct_message_users(@chat, channel)}
              selected={Chat.current?(@chat, channel)}
              active={Chat.has_activity?(@chat, channel)}
              online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
              unread_count={Chat.unread_count(@chat, channel)}
              phx-click={JS.patch(~p"/chat/#{channel.id}")}
            />
          </.sidebar_section>

          <.notice :if={!@current_user}>
            Sign in to use the direct messaging feature.
          </.notice>
        </.sidebar>
      </:sidebar>

      <.chat_header channel={@chat.current_channel} users_fun={&Chat.direct_message_users(@chat, &1)} />

      <.chat>
        <.message
          :for={message <- group_messages(@chat.messages)}
          user={message.sent_by_user}
          user_detail_patch={~p"/chat/#{@chat.current_channel}?profile=#{message.sent_by_user}"}
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
        :if={@current_user}
        id={"chat_component_#{@chat.current_channel.id}"}
        module={LaxWeb.ChatLive.ChannelChatComponent}
        chat={@chat}
      />

      <.notice :if={!@current_user} class="mx-4 mb-4 -mt-2">
        You are viewing this channel anonymously. Sign in to send messages.
      </.notice>

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
          on_cancel={JS.patch(~p"/chat/#{@chat.current_channel}")}
        />
      </:right_sidebar>
    </.container>

    <.modal :if={@modal == :new_channel} id="new_channel_modal" show on_cancel={JS.push("hide_modal")}>
      <.live_component
        id="new_channel_form"
        module={__MODULE__.ChannelFormComponent}
        current_user={@current_user}
      />
    </.modal>

    <.modal
      :if={@modal == :manage_channels}
      id="manage_channels_modal"
      show
      on_cancel={JS.push("hide_modal")}
    >
      <.live_component
        id="manage_channels"
        module={__MODULE__.ManageChannelsComponent}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :home)
     |> assign(:modal, nil)
     |> assign(:chat, Chat.load(socket.assigns.current_user))
     |> ChannelChatComponent.handle_form()
     |> LaxWeb.Presence.Live.track_online_users()}
  end

  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:swiftui_tab, swiftui_tab_from_params(params))
     |> apply_chat_params(params)
     |> apply_profile_params(params)
     |> put_page_title()}
  end

  def apply_chat_params(socket, %{"id" => channel_id}) do
    update(socket, :chat, &Chat.select_channel(&1, channel_id))
  end

  def apply_chat_params(socket, _params) do
    socket
  end

  def apply_profile_params(socket, %{"profile" => user_id}) do
    assign(socket, :user_profile, Users.get_user!(user_id))
  end

  def apply_profile_params(socket, _params) do
    assign(socket, :user_profile, nil)
  end

  def handle_event("resize", %{"width" => width}, socket) do
    if user = socket.assigns.current_user do
      {:ok, user} = Users.update_user_ui_settings(user, %{channels_sidebar_width: width})
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

  def handle_event("show_new_channel", _params, socket) do
    {:noreply, assign(socket, :modal, :new_channel)}
  end

  def handle_event("show_manage_channels", _params, socket) do
    {:noreply, assign(socket, :modal, :manage_channels)}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end

  def handle_event("delete_message", %{"id" => message_id}, socket) do
    {:noreply, update(socket, :chat, &Chat.delete_message(&1, message_id))}
  end

  ## SwiftUI

  def handle_event("swiftui_tab_selection", %{"selection" => selection}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?#{%{swiftui_tab: selection}}", replace: true)}
  end

  def handle_event("swiftui_navigate", %{"to" => to}, socket) do
    {:noreply, push_navigate(socket, to: to)}
  end

  def handle_event("swiftui_user_detail_patch", %{"profile" => _user_id} = params, socket) do
    {:noreply, apply_profile_params(socket, params)}
  end

  def handle_event("swiftui_user_detail_patch", _params, socket) do
    {:noreply, assign(socket, user_profile: nil)}
  end

  def handle_event("swiftui_unregister_apns", _params, socket) do
    {:ok, user} = Users.update_user_apns_device_token(socket.assigns.current_user, [])
    {:noreply, assign(socket, :current_user, user)}
  end

  def handle_event("swiftui_register_apns" = event, params, socket) do
    {:noreply, push_event(socket, event, params)}
  end

  def handle_event("swiftui_apns_device_token", %{"device_token" => device_token}, socket) do
    {:ok, user} = Users.update_user_apns_device_token(socket.assigns.current_user, [device_token])
    {:noreply, assign(socket, :current_user, user)}
  end

  def handle_event("swiftui_apns_device_token", %{"error" => _error}, socket) do
    {:noreply, put_flash(socket, :error, "Failed to register with push notification service")}
  end

  def handle_event("swiftui_" <> event, params, socket) do
    ChannelChatComponent.handle_event(event, params, socket)
  end

  ## /SwiftUI

  def handle_info({ChannelFormComponent, {:create_channel, channel}}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> push_patch(to: ~p"/chat/#{channel}")}
  end

  def handle_info({ManageChannelsComponent, :update_channels}, socket) do
    {:noreply, update(socket, :chat, &Chat.reload_channels(&1))}
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

  def sidebar_width(nil), do: 250
  def sidebar_width(current_user), do: current_user.ui_settings.channels_sidebar_width

  def profile_sidebar_width(nil), do: 500
  def profile_sidebar_width(current_user), do: current_user.ui_settings.profile_sidebar_width

  def swiftui_tab_from_params(%{"swiftui_tab" => "direct_messages"}), do: :direct_messages
  def swiftui_tab_from_params(_otherwise), do: :home
end
