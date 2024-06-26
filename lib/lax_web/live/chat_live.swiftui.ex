defmodule LaxWeb.ChatLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  alias Lax.Chat
  alias Lax.Messages.Message

  import LaxWeb.ChatLive.Components, only: [group_messages: 1]
  import LaxWeb.ChatLive.Components.SwiftUI
  import LaxWeb.DirectMessageLive.Components.SwiftUI
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

    <.tab_bar phx-change="swiftui_tab_selection" selection={@swiftui_tab}>
      <.tab tag={:home} name="Home" icon_system_name="house">
        <.workspace_list>
          <.workspace_section title="Channels">
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              active={Chat.has_activity?(@chat, channel)}
              unread_count={Chat.unread_count(@chat, channel)}
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
            <:footer :if={!@current_user}>
              Sign in to use the direct messaging feature.
            </:footer>
          </.workspace_section>
        </.workspace_list>
      </.tab>

      <.tab tag={:direct_messages} name="DMs" icon_system_name="message">
        <Text :if={!@current_user} style="font(.subheadline);">
          Sign in to use the direct messaging feature.
        </Text>
        <.direct_message_list :if={@current_user}>
          <.direct_message_item_row
            :for={message <- @chat.latest_message_in_direct_messages}
            current_user={@current_user}
            users={Chat.direct_message_users(@chat, message.channel)}
            online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
            latest_message={message}
            selected={Chat.current?(@chat, message.channel)}
            navigate={~p"/chat/#{message.channel}"}
          />
        </.direct_message_list>
      </.tab>
    </.tab_bar>
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

    <.chat_form
      :if={@current_user}
      chat={@chat}
      form={@chat_form}
      phx-validate="swiftui_validate"
      phx-submit="swiftui_submit"
    />

    <Text
      :if={!@current_user}
      style={[
        "font(.subheadline);",
        "padding(.horizontal); padding(.vertical, 12);",
        "overlay(content: :border);",
        "padding(.horizontal); padding(.bottom);",
      ]}
    >
      <RoundedRectangle template={:border} cornerRadius={4} style="stroke(.gray);" />
      You are viewing this channel anonymously. Sign in to send messages.
    </Text>
    """
  end
end
