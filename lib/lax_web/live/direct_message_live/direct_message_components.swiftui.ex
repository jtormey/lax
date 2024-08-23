defmodule LaxWeb.DirectMessageLive.Components.SwiftUI do
  use LiveViewNative.Component

  import LaxWeb.UserLive.Components.SwiftUI
  import LiveViewNative.SwiftUI.Component

  alias Lax.Messages.Message

  slot :inner_block, required: true

  def direct_message_list(assigns) do
    ~LVN"""
    <List style="listStyle(.plain);">
      <%= render_slot(@inner_block) %>
    </List>
    """
  end

  attr :current_user, Lax.Users.User
  attr :users, :list, required: true
  attr :latest_message, Lax.Messages.Message, required: true
  attr :selected, :boolean, default: false
  attr :online_fun, :any, required: true
  attr :navigate, :string, required: true

  def direct_message_item_row(assigns) do
    ~LVN"""
    <.link navigate={@navigate} style="foregroundStyle(.primary);">
      <HStack alignment="top">
        <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:md} />
        <VStack alignment="leading">
          <HStack style="padding(.bottom, 1);">
            <Text style="font(.headline);">
              <%= Enum.map_join(@users, ", ", &Lax.Users.User.display_name/1) %>
            </Text>
            <Spacer />
            <Text style="font(.footnote);">
              <%= Message.show_time(@latest_message, @current_user && @current_user.time_zone) %>
            </Text>
          </HStack>
          <Text style="font(.subheadline);">
            <%= Lax.Users.User.display_name(@latest_message.sent_by_user) %>: <%= @latest_message.text %>
          </Text>
        </VStack>
      </HStack>
    </.link>
    """
  end
end
