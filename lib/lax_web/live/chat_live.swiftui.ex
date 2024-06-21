defmodule LaxWeb.ChatLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  alias Lax.Chat
  alias Lax.Messages.Message

  import LaxWeb.ChatLive.Components, only: [group_messages: 1]
  import LaxWeb.ChatLive.Components.SwiftUI
  import LaxWeb.UserLive.Components.SwiftUI

  def render(%{live_action: :chat} = assigns, _interface) do
    ~LVN"""
    <.header>
      Workspace
      <:actions>
        <.link :if={!@current_user} navigate={~p"/users/register"} class="font-weight-semibold fg-tint">
          Sign in or register
        </.link>
        <.user_options :if={@current_user}>
          <:option navigate={~p"/users/sign-out"} system_image="arrow.up.backward.square">
            Sign out
          </:option>
          <.user_profile :if={@current_user} user={@current_user} size={:md} online />
        </.user_options>
      </:actions>
    </.header>

    <.workspace_list>
      <.workspace_section title="Channels">
        <.channel_item
          :for={channel <- @chat.channels}
          name={channel.name}
          active={Chat.has_activity?(@chat, channel)}
          navigate={~p"/chat/#{channel}"}
        />
      </.workspace_section>

      <.workspace_section title="Direct messages">
        <.direct_message_item
          :for={channel <- @chat.direct_messages}
          users={Chat.direct_message_users(@chat, channel)}
          active={Chat.has_activity?(@chat, channel)}
          online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
          unread_count={Chat.unread_count(@chat, channel)}
          navigate={~p"/chat/#{channel}"}
        />
      </.workspace_section>
    </.workspace_list>
    """
  end

  def render(%{live_action: :chat_selected} = assigns, _interface) do
    ~LVN"""
    <.chat_header channel={@chat.current_channel} users_fun={&Chat.direct_message_users(@chat, &1)} />

    <.chat animation_key={length(@chat.messages)}>
      <.message
        :for={message <- Enum.reverse(group_messages(@chat.messages))}
        message_id={message.id}
        user={message.sent_by_user}
        online={LaxWeb.Presence.Live.online?(assigns, message.sent_by_user)}
        time={Message.show_time(message, @current_user && @current_user.time_zone)}
        text={message.text}
        compact={message.compact}
        on_delete={@current_user && @current_user.id == message.sent_by_user_id && "delete_message"}
      />
    </.chat>
    """
  end
end
