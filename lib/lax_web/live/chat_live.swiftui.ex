defmodule LaxWeb.ChatLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  alias Lax.Chat
  alias Lax.Messages.Message

  import LaxWeb.ChatLive.Components, only: [group_messages: 1]
  import LaxWeb.ChatLive.Components.SwiftUI
  import LaxWeb.DirectMessageLive.Components.SwiftUI
  import LaxWeb.UserLive.Components.SwiftUI

  def render(assigns, %{"target" => "macos" = target}) do
    assigns = assign(assigns, target: target)
    ~LVN"""
    <.header>
      Workspace
      <:actions placement="automatic">
        <.link :if={!@current_user} navigate={~p"/users/register"} class="font-weight-semibold fg-tint">
          Sign in or register
        </.link>
        <.user_options :if={@current_user}>
          <:option navigate={~p"/users/sign-out"} system_image="arrow.up.backward.square">
            Sign out
          </:option>
          <:option :if={length(@current_user.apns_device_token) == 0} on_click="swiftui_register_apns" system_image="bell.badge">
            Enable notifications
          </:option>
          <:option :if={length(@current_user.apns_device_token) > 0} on_click="swiftui_unregister_apns" system_image="bell.badge.slash">
            Disable notifications
          </:option>
          <Text><%= @current_user.username %></Text>
        </.user_options>
      </:actions>
      <:actions placement="automatic">
        <Group>
          <.link :if={@current_user != nil} navigate={~p"/new-direct-message"}>
            <Label systemImage="square.and.pencil">
              Direct Message
            </Label>
          </.link>
        </Group>
      </:actions>
    </.header>

    <NavigationSplitView>
      <Group template="sidebar">
        <.workspace_list id="sidebar_list" selection={@chat.current_channel.id} phx-change="swiftui_select_chat">
          <.workspace_section title="Channels">
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              active={Chat.has_activity?(@chat, channel)}
              unread_count={Chat.unread_count(@chat, channel)}
              target={@target}
              id={channel.id}
            >
              <:menu_items>
                <Button role="destructive" phx-click="swiftui_leave_channel" phx-value-id={channel.id}>
                  <Label systemImage="rectangle.portrait.and.arrow.right">Leave</Label>
                </Button>
              </:menu_items>
            </.channel_item>
          </.workspace_section>

          <.workspace_section title="Direct messages">
            <.direct_message_item
              :for={channel <- @chat.direct_messages}
              users={Chat.direct_message_users(@chat, channel)}
              active={Chat.has_activity?(@chat, channel)}
              online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
              unread_count={Chat.unread_count(@chat, channel)}
              target={@target}
              id={channel.id}
            />
            <:footer :if={!@current_user}>
              Sign in to use the direct messaging feature.
            </:footer>
          </.workspace_section>
        </.workspace_list>
      </Group>
      <Group template="content" :if={@chat}>
        <.user_profile_sidebar
          user={@user_profile}
          online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
          current_user={@current_user}
        >
          <.chat animation_key={length(@chat.messages)} target={@target}>
            <.message
              :for={message <- Enum.reverse(group_messages(@chat.messages))}
              message_id={message.id}
              user={message.sent_by_user}
              user_detail_patch={message.sent_by_user.id}
              online={LaxWeb.Presence.Live.online?(assigns, message.sent_by_user)}
              time={Message.show_time(message, @current_user && @current_user.time_zone)}
              text={message.text}
              compact={message.compact}
              on_delete={@current_user && @current_user.id == message.sent_by_user_id && "delete_message"}
            />
            <:bottom_bar>
              <.chat_form
                :if={@current_user}
                placeholder={LaxWeb.ChatLive.ChannelChatComponent.placeholder(@chat.current_channel)}
                form={@chat_form}
                target={@target}
                phx-change="swiftui_validate"
                phx-submit="swiftui_submit"
              />
              <.chat_signed_out_notice :if={!@current_user} />
            </:bottom_bar>
          </.chat>
        </.user_profile_sidebar>
      </Group>
    </NavigationSplitView>
    """
  end

  def render(%{live_action: :chat} = assigns, _interface) do
    ~LVN"""
    <.header>
      Workspace
      <:actions placement="primaryAction">
        <.link :if={!@current_user} navigate={~p"/users/register"} class="font-weight-semibold fg-tint">
          Sign in or register
        </.link>
        <.user_options :if={@current_user}>
          <:option navigate={~p"/users/sign-out"} system_image="arrow.up.backward.square">
            Sign out
          </:option>
          <:option :if={length(@current_user.apns_device_token) == 0} on_click="swiftui_register_apns" system_image="bell.badge">
            Enable notifications
          </:option>
          <:option :if={length(@current_user.apns_device_token) > 0} on_click="swiftui_unregister_apns" system_image="bell.badge.slash">
            Disable notifications
          </:option>
          <.user_profile :if={@current_user} user={@current_user} size={:md} online />
        </.user_options>
      </:actions>
      <:actions placement="navigation">
        <Group>
          <Menu :if={@current_user != nil and @swiftui_tab == :home}>
            <Image template="label" systemName="plus" />

            <.button phx-click="show_manage_channels">
              <Label systemImage="person.badge.plus">Join Channel</Label>
            </.button>
            <.button phx-click="show_new_channel">
              <Label systemImage="square.and.pencil">Create Channel</Label>
            </.button>
          </Menu>
          <.link :if={@current_user != nil and @swiftui_tab == :direct_messages} navigate={~p"/new-direct-message"}>
            <Image systemName="square.and.pencil" />
          </.link>
        </Group>
      </:actions>
    </.header>

    <.tab_bar phx-change="swiftui_tab_selection" selection={@swiftui_tab}>
      <.tab tag={:home} name="Home" icon_system_name="house">
        <.workspace_list id="home_list">
          <.workspace_section title="Channels">
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              active={Chat.has_activity?(@chat, channel)}
              unread_count={Chat.unread_count(@chat, channel)}
              navigate={~p"/chat/#{channel}"}
            >
              <:menu_items>
                <Button role="destructive" phx-click="swiftui_leave_channel" phx-value-id={channel.id}>
                  <Label systemImage="rectangle.portrait.and.arrow.right">Leave</Label>
                </Button>
              </:menu_items>
            </.channel_item>
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

      <.tab tag={:direct_messages} name="DMs" icon_system_name="bubble.left.and.text.bubble.right">
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

    <VStack
      :if={@modal == :manage_channels}
      style={[
        "hidden()",
        ~s[confirmationDialog("Join Channels", isPresented: attr("isPresented"), titleVisibility: .visible, actions: :actions)]
      ]}
      isPresented={true}
      phx-change="hide_modal"
    >
      <Group template="actions">
        <Button
          :for={channel <- @channels}
          :if={not Enum.member?(@chat.channels, channel)}
          phx-click="swiftui_join_channel"
          phx-value-id={channel.id}
        >
          <%= channel.name %>
        </Button>
      </Group>
    </VStack>

    <.modal :if={@modal == :new_channel} id="new_channel_modal" show on_cancel="hide_modal">
      <.simple_form for={@swiftui_channel_form} phx-change="swiftui_channel_form_validate" phx-submit="swiftui_channel_form_submit">
        <.input field={@swiftui_channel_form[:name]} label="Name" style="textInputAutocapitalization(.never); autocorrectionDisabled();" />
        <:actions>
          <.button type="submit">Create</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  def render(%{live_action: :chat_selected} = assigns, _interface) do
    ~LVN"""
    <.chat_header channel={@chat.current_channel} users_fun={&Chat.direct_message_users(@chat, &1)} />

    <.user_profile_sidebar
      user={@user_profile}
      online_fun={&LaxWeb.Presence.Live.online?(assigns, &1)}
      current_user={@current_user}
    >
      <.chat animation_key={length(@chat.messages)}>
        <.message
          :for={message <- Enum.reverse(group_messages(@chat.messages))}
          message_id={message.id}
          user={message.sent_by_user}
          user_detail_patch={message.sent_by_user.id}
          online={LaxWeb.Presence.Live.online?(assigns, message.sent_by_user)}
          time={Message.show_time(message, @current_user && @current_user.time_zone)}
          text={message.text}
          compact={message.compact}
          on_delete={@current_user && @current_user.id == message.sent_by_user_id && "delete_message"}
        />
        <:bottom_bar>
          <.chat_form
            :if={@current_user}
            placeholder={LaxWeb.ChatLive.ChannelChatComponent.placeholder(@chat.current_channel)}
            form={@chat_form}
            phx-change="swiftui_validate"
            phx-submit="swiftui_submit"
          />
          <.chat_signed_out_notice :if={!@current_user} />
        </:bottom_bar>
      </.chat>
    </.user_profile_sidebar>
    """
  end
end
