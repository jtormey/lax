defmodule LaxWeb.ChatLive.Components.SwiftUI do
  use LiveViewNative.Component

  import LiveViewNative.LiveForm.Component
  import LiveViewNative.SwiftUI.Component

  import LaxWeb.CoreComponents.SwiftUI
  import LaxWeb.UserLive.Components.SwiftUI

  alias LaxWeb.ChatLive.ChannelChatComponent

  attr :rest, :global, include: ~w(phx-change selection)
  slot :inner_block, required: true

  def tab_bar(assigns) do
    ~LVN"""
    <TabView {@rest}>
      <%= render_slot(@inner_block) %>
    </TabView>
    """
  end

  attr :tag, :any, required: true
  attr :name, :string, required: true
  attr :icon_system_name, :string, required: true
  slot :inner_block, required: true

  def tab(assigns) do
    ~LVN"""
    <Group tag={@tag} style="tabItem(:tab);">
      <Image template={:tab} systemName={@icon_system_name} />
      <Text template={:tab}><%= @name %></Text>
      <%= render_slot(@inner_block) %>
    </Group>
    """
  end

  attr :rest, :global

  slot :option do
    attr :navigate, :string
    attr :system_image, :string
  end

  slot :inner_block, required: true

  def user_options(assigns) do
    ~LVN"""
    <Group {@rest} style='contextMenu(menuItems: :user_menu);'>
      <HStack template={:user_menu}>
      <.link :for={option <- @option} navigate={option[:navigate]}>
        <Label systemImage={option[:system_image]}>
          <%= render_slot(option) %>
        </Label>
      </.link>
      </HStack>
      <%= render_slot(@inner_block) %>
    </Group>
    """
  end

  slot :inner_block, required: true

  def workspace_list(assigns) do
    ~LVN"""
    <List>
      <%= render_slot(@inner_block) %>
    </List>
    """
  end

  attr :title, :string, required: true
  slot :footer, default: []
  slot :inner_block, required: true

  def workspace_section(assigns) do
    ~LVN"""
    <Section>
      <Text template="header">
        <%= @title %>
      </Text>
      <Text :if={@footer != []} template="footer">
        <%= render_slot(@footer) %>
      </Text>
      <%= render_slot(@inner_block) %>
    </Section>
    """
  end

  attr :name, :string, required: true
  attr :active, :boolean, default: false
  attr :unread_count, :integer, default: 0
  attr :rest, :global, include: ~w(navigate)

  def channel_item(assigns) do
    ~LVN"""
    <.link {@rest}>
      <LabeledContent style='badge(attr("count"))' count={@unread_count}>
        <Text template="label"># <%= @name %></Text>
      </LabeledContent>
    </.link>
    """
  end

  attr :users, :list, required: true
  attr :selected, :boolean, default: false
  attr :active, :boolean, default: false
  attr :online_fun, :any, required: true
  attr :unread_count, :integer, default: 0
  attr :rest, :global, include: ~w(navigate)

  def direct_message_item(assigns) do
    ~LVN"""
    <.link {@rest}>
      <LabeledContent style="badge(:badge)">
        <HStack template="label">
          <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:xs} />
          <Text>
            <%= Enum.map_join(@users, ", ", & &1.username) %>
          </Text>
        </HStack>
        <Text :if={@active} template={:badge}>
          <%= @unread_count %>
        </Text>
      </LabeledContent>
    </.link>
    """
  end

  attr :channel, Lax.Channels.Channel, required: true
  attr :users_fun, :any

  def chat_header(%{channel: %{type: :channel}} = assigns) do
    ~LVN"""
    <.header>
      #<%= @channel.name %>
    </.header>
    """
  end

  def chat_header(%{channel: %{type: :direct_message}} = assigns) do
    ~LVN"""
    <.header>
      @<%= Enum.map_join(@users_fun.(@channel), ", ", & &1.username) %>
    </.header>
    """
  end

  attr :animation_key, :any
  slot :inner_block
  slot :bottom_bar

  def chat(assigns) do
    ~LVN"""
    <ScrollView style="scrollDismissesKeyboard(.immediately); defaultScrollAnchor(.bottom); safeAreaInset(edge: .bottom, content: :bottom_bar);">
      <VStack
        alignment="leading"
        style='frame(maxWidth: .infinity, alignment: .leading); animation(.default, value: attr("animation_key"));'
        animation_key={@animation_key}
      >
        <%= render_slot(@inner_block) %>
      </VStack>
      <VStack spacing="0" template={:bottom_bar} style="background(.bar);">
        <Divider />
        <%= render_slot(@bottom_bar) %>
      </VStack>
    </ScrollView>
    """
  end

  attr :message_id, :string, required: true
  attr :user, Lax.Users.User, required: true
  attr :online, :boolean, required: true
  attr :time, :string, required: true
  attr :text, :string, required: true
  attr :compact, :boolean, required: true
  attr :on_delete, JS, default: nil

  def message(%{compact: true} = assigns) do
    ~LVN"""
    <Group style='padding(.horizontal, 56); padding(.bottom, 1); contextMenu(menuItems: :delete_menu);'>
      <Button
        :if={@on_delete}
        role="destructive"
        template={:delete_menu}
        phx-click={@on_delete}
        phx-value-id={@message_id}
      >
        <Label systemImage="trash">
          Delete message
        </Label>
      </Button>
      <HStack style='frame(maxWidth: :infinity);'>
        <VStack alignment="leading">
          <Text markdown={@text} />
        </VStack>
        <Spacer />
      </HStack>
    </Group>
    """
  end

  def message(assigns) do
    ~LVN"""
    <Group style="padding(.horizontal); padding(.bottom, 1); contextMenu(menuItems: :delete_menu);">
      <Button
        :if={@on_delete}
        role="destructive"
        template={:delete_menu}
        phx-click={@on_delete}
        phx-value-id={@message_id}
      >
        <Label systemImage="trash">
          Delete message
        </Label>
      </Button>
      <HStack style='frame(maxWidth: .infinity);'>
        <VStack style='padding(.top, 2)'>
          <.user_profile user={@user} size={:md} online={@online} />
          <Spacer />
        </VStack>
        <VStack alignment="leading">
          <HStack>
            <Text style="font(.headline);">
              <%= @user.username %>
            </Text>
            <Spacer />
            <Text style="font(.caption2); padding(.top, 4);">
              <%= @time %>
            </Text>
          </HStack>
          <Text style="font(.body);" markdown={@text} />
        </VStack>
        <Spacer />
      </HStack>
    </Group>
    """
  end

  attr :chat, Lax.Chat, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :rest, :global

  def chat_form(assigns) do
    ~LVN"""
    <HStack style="padding(.leading); padding(.vertical, 8); padding(.trailing, 8);">
      <.form {@rest} for={@form}>
        <.input
          field={Map.put(@form[:text], :errors, [])}
          placeholder={ChannelChatComponent.placeholder(@chat.current_channel)}
        />
        <LiveSubmitButton
          style={[
            "buttonStyle(.borderedProminent)",
            "buttonBorderShape(.circle)",
            "controlSize(.small)",
            ~s[disabled(attr("disabled"))]
          ]}
          after-submit="clear"
          disabled={not @form.source.valid?}
        >
          <Image systemName="paperplane.fill" style="padding(4);" />
        </LiveSubmitButton>
      </.form>
    </HStack>
    """
  end

  def chat_signed_out_notice(assigns) do
    ~LVN"""
    <Text
      style={[
        "font(.subheadline);",
        "padding(.horizontal); padding(.vertical, 12);",
        "overlay(content: :border);",
        "padding(.horizontal); padding(.vertical);",
      ]}
    >
      <RoundedRectangle template={:border} cornerRadius={4} style="stroke(.gray);" />
      You are viewing this channel anonymously. Sign in to send messages.
    </Text>
    """
  end
end
