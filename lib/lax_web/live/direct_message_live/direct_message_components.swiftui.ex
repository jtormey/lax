defmodule LaxWeb.DirectMessageLive.Components.SwiftUI do
  use LiveViewNative.Component

  import LaxWeb.UserLive.Components.SwiftUI

  alias Lax.Messages.Message

  slot :inner_block, required: true

  def direct_message_list(assigns) do
    ~LVN"""
    <ScrollView style="toolbarTitleMenu(content: :toolbar);">
      <VStack alignment="leading">
        <%= render_slot(@inner_block) %>
      </VStack>
      <Button template="toolbar">
        <Image systemName="plus" />
      </Button>
    </ScrollView>
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
    <HStack alignment="top" style="padding(); background(.background);" phx-click="swiftui_navigate" phx-value-to={@navigate}>
      <.user_profile user={hd(@users)} online={@online_fun.(hd(@users))} size={:md} />
      <VStack alignment="leading">
        <HStack style="padding(.bottom, 1);">
          <Text style="font(.headline);">
            <%= Enum.map_join(@users, ", ", & &1.username) %>
          </Text>
          <Spacer />
          <Text style="font(.footnote);">
            <%= Message.show_time(@latest_message, @current_user && @current_user.time_zone) %>
          </Text>
        </HStack>
        <Text style="font(.subheadline);">
          <%= @latest_message.sent_by_user.username%>: <%= @latest_message.text %>
        </Text>
      </VStack>
    </HStack>
    <Divider />
    """
  end
end
