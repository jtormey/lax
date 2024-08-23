defmodule LaxWeb.ChatLive.Components.SwiftUI do
  use LaxNative, [:component, format: :swiftui]

  import LiveViewNative.LiveForm.Component
  import LiveViewNative.SwiftUI.Component

  import LaxWeb.CoreComponents.SwiftUI
  import LaxWeb.UserLive.Components.SwiftUI

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
    attr :on_click, :string
    attr :system_image, :string
    attr :role, :atom, values: [:destructive]
  end

  slot :inner_block, required: true

  def user_options(assigns) do
    ~LVN"""
    <Menu {@rest}>
      <Group template="label">
        <%= render_slot(@inner_block) %>
      </Group>
      <%= for option <- @option do %>
        <%= cond do %>
        <% navigate = option[:navigate] -> %>
          <.link navigate={navigate}>
            <Label systemImage={option[:system_image]}>
              <%= render_slot(option) %>
            </Label>
          </.link>
        <% on_click = option[:on_click] -> %>
          <.button phx-click={on_click} role={option[:role]}>
            <Label systemImage={option[:system_image]}>
              <%= render_slot(option) %>
            </Label>
          </.button>
        <% end %>
      <% end %>
    </Menu>
    """
  end

  attr :rest, :global, include: ~w(selection)
  slot :inner_block, required: true

  def workspace_list(assigns) do
    ~LVN"""
    <List {@rest}>
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
  attr :target, :string, default: "ios"
  attr :rest, :global, include: ~w(navigate id)
  slot :menu_items

  def channel_item(%{target: "macos"} = assigns) do
    ~LVN"""
    <Group style='contextMenu(menuItems: :menu_items);'>
      <LabeledContent {@rest} style='badge(attr("count"))' count={@unread_count}>
        <Text template="label"># <%= @name %></Text>
      </LabeledContent>
      <Group template="menu_items">
        <%= render_slot(@menu_items) %>
      </Group>
    </Group>
    """
  end

  def channel_item(assigns) do
    ~LVN"""
    <Group style='contextMenu(menuItems: :menu_items);'>
      <.link {@rest}>
        <LabeledContent style='badge(attr("count"))' count={@unread_count}>
          <Text template="label"># <%= @name %></Text>
        </LabeledContent>
      </.link>
      <Group template="menu_items">
        <%= render_slot(@menu_items) %>
      </Group>
    </Group>
    """
  end

  attr :users, :list, required: true
  attr :selected, :boolean, default: false
  attr :active, :boolean, default: false
  attr :online_fun, :any, required: true
  attr :unread_count, :integer, default: 0
  attr :target, :string, default: "ios"
  attr :rest, :global, include: ~w(navigate id)

  def direct_message_item(%{target: "macos"} = assigns) do
    ~LVN"""
    <LabeledContent {@rest} style='badge(attr("count"));' count={@unread_count}>
        <HStack template="label">
          <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:xs} />
          <Text>
            <%= Enum.map_join(@users, ", ", &Lax.Users.User.display_name/1) %>
          </Text>
        </HStack>
      </LabeledContent>
    """
  end

  def direct_message_item(assigns) do
    ~LVN"""
    <.link {@rest}>
      <LabeledContent style='badge(attr("count"));' count={@unread_count}>
        <HStack template="label">
          <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:xs} />
          <Text>
            <%= Enum.map_join(@users, ", ", &Lax.Users.User.display_name/1) %>
          </Text>
        </HStack>
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
      @<%= Enum.map_join(@users_fun.(@channel), ", ", &Lax.Users.User.display_name/1) %>
    </.header>
    """
  end

  attr :animation_key, :any
  attr :target, :string, default: "ios"
  slot :inner_block
  slot :bottom_bar

  def chat(%{target: "macos"} = assigns) do
    ~LVN"""
    <ScrollView style="scrollDismissesKeyboard(.immediately); defaultScrollAnchor(.bottom); safeAreaInset(edge: .bottom, content: :bottom_bar);">
      <VStack
        alignment="leading"
        style='frame(maxWidth: .infinity, alignment: .leading); animation(.default, value: attr("animation_key")); padding(.top);'
        animation_key={@animation_key}
      >
        <%= render_slot(@inner_block) %>
      </VStack>
      <VStack spacing="0" template={:bottom_bar} style="background(.bar, in: .rect(cornerRadius: 8)); background(content: :stroke); padding();">
        <%= render_slot(@bottom_bar) %>
        <RoundedRectangle template="stroke" cornerRadius="8" style="stroke(.separator, lineWidth: 2);" />
      </VStack>
    </ScrollView>
    """
  end

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
  attr :user_detail_patch, :string
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
          <Text markdown={@text} style="textSelection(.enabled);" />
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
            <Button style="buttonStyle(.plain);" phx-click="swiftui_user_detail_patch" phx-value-profile={@user_detail_patch}>
              <Text style="font(.headline); foregroundStyle(.primary);">
                <%= Lax.Users.User.display_name(@user) %>
              </Text>
            </Button>
            <Spacer />
            <Text style="font(.caption2); foregroundStyle(.secondary); padding(.top, 4);">
              <%= @time %>
            </Text>
          </HStack>
          <Text style="font(.body); textSelection(.enabled);" markdown={@text} />
        </VStack>
        <Spacer />
      </HStack>
    </Group>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :placeholder, :string, required: true
  attr :target, :string, default: "ios"
  attr :rest, :global, include: ~w(phx-change phx-submit phx-target)

  def chat_form(%{target: "macos"} = assigns) do
    ~LVN"""
    <VStack alignment="trailing" style="padding(.leading); padding(.vertical, 8); padding(.trailing, 8);">
      <.form {@rest} for={@form}>
        <.input
          field={Map.put(@form[:text], :errors, [])}
          placeholder={@placeholder}
          style="textFieldStyle(.plain); padding(.vertical, 4);"
          axis="vertical"
        />
        <LiveSubmitButton
          style={[
            "buttonStyle(.borderedProminent)",
            ~s[disabled(attr("disabled"))]
          ]}
          after-submit="clear"
          disabled={not @form.source.valid?}
        >
          <Image systemName="paperplane.fill" style="padding(4);" />
        </LiveSubmitButton>
      </.form>
    </VStack>
    """
  end

  def chat_form(assigns) do
    ~LVN"""
    <HStack style="padding(.leading); padding(.vertical, 8); padding(.trailing, 8);">
      <.form {@rest} for={@form}>
        <.input
          field={Map.put(@form[:text], :errors, [])}
          placeholder={@placeholder}
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
        "font(.subheadline)",
        "padding(.horizontal); padding(.vertical, 12);",
        "frame(maxWidth: .infinity)",
        "overlay(content: :border)",
        "padding(.horizontal); padding(.vertical)"
      ]}
    >
      <RoundedRectangle template={:border} cornerRadius={4} style="stroke(.gray);" />
      You are viewing this channel anonymously. Sign in to send messages.
    </Text>
    """
  end

  attr :user, Lax.Users.User
  attr :online_fun, :any, required: true
  attr :current_user, Lax.Users.User
  slot :inner_block

  def user_profile_sidebar(assigns) do
    ~LVN"""
    <VStack
      style={[
        ~s[inspector(isPresented: attr("is-presented"), content: :content)]
      ]}
      is-presented={@user != nil}
      phx-change="swiftui_user_detail_patch"
    >
      <%= render_slot(@inner_block) %>
      <ScrollView
        template="content"
        :if={@user}
        style={[
          ~s[tint(attr("display_color"))],
          ~s[navigationTitle("Profile")]
        ]}
        display_color={@user.display_color}
      >
        <VStack
          alignment="leading"
          style="padding();"
        >
          <.user_profile user={@user} online={@online_fun.(@user)} size={:xl} />
          <Text style="font(.title2); bold();"><%= Lax.Users.User.display_name(@user) %></Text>

          <LabeledContent>
            <Text template="label">Status</Text>
            <Text><%= if @online_fun.(@user), do: "Online", else: "Away" %></Text>
          </LabeledContent>

          <LabeledContent>
            <% local_time = DateTime.shift_zone!(DateTime.utc_now(), @user.time_zone) %>
            <% local_time_strftime = Calendar.strftime(local_time, "%-I:%M%P") %>
            <Text template="label">Timezone</Text>
            <Text><%= @user.time_zone %> (<%= local_time_strftime %> local)</Text>
          </LabeledContent>

          <.link
            :if={@current_user && @user.deleted_at == nil}
            navigate={~p"/new-direct-message?to_user=#{@user}"}
            style='buttonStyle(.borderedProminent); controlSize(.large); padding(.vertical);'
          >
            <Text style="frame(maxWidth: .infinity);">Direct message</Text>
          </.link>
        </VStack>
      </ScrollView>
    </VStack>
    """
  end
end
