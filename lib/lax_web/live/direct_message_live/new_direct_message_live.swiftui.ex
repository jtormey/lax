defmodule LaxWeb.DirectMessageLive.NewDirectMessageLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  import LaxWeb.UserLive.Components.SwiftUI
  import LaxWeb.ChatLive.Components.SwiftUI

  def render(assigns, _interface) do
    ~LVN"""
    <Group
      style={[
        ~s[searchable(text: attr("filter"), placement: .navigationBarDrawer(displayMode: .always), prompt: "Add users")],
        "safeAreaInset(edge: .bottom, content: :chat_form)",
        "safeAreaInset(edge: .top, content: :group)",
        ~s[navigationTitle("New Message")]
      ]}
      filter={@filter}
      phx-change="filter"
    >
      <List
        style={[
          "listStyle(.plain)",
          ~s[animation(.default, value: attr("selected_user_ids"))]
        ]}
        selected_user_ids={Enum.into(@selected_user_ids, [])}
      >
        <Button
          :for={user <- @filtered_users}
          :if={user.id not in @selected_user_ids}
          phx-click="add"
          phx-value-id={user.id}
        >
          <HStack>
            <.user_profile
              user={user}
              online={LaxWeb.Presence.Live.online?(assigns, user)}
              size={:md}
            />
            <Text><%= user.username %></Text>
            <Spacer />
            <Image systemName="plus" style="foregroundStyle(.tint);" />
          </HStack>
        </Button>
      </List>

      <VStack
        template="chat_form"
        spacing="0"
        style="background(.bar);"
      >
        <Divider />
        <.chat_form
          form={@chat_form}
          placeholder="Start a new message"
          phx-change="validate"
          phx-submit="submit"
        />
      </VStack>

      <VStack template="group" spacing="0" :if={MapSet.size(@selected_user_ids) > 0}>
        <ScrollView axes="horizontal" style="background(.bar);">
          <HStack style="padding(.horizontal); padding(.vertical, 8); buttonStyle(.bordered); buttonBorderShape(.roundedRectangle); controlSize(.small);">
            <Button
              :for={user <- Enum.map(@selected_user_ids, fn id -> Enum.find(@users, &(&1.id == id)) end)}
              phx-click="remove"
              phx-value-id={user.id}
              style="fixedSize(horizontal: true, vertical: false);"
            >
              <HStack style="padding(.leading, -4);">
                <.user_profile
                  user={user}
                  online={LaxWeb.Presence.Live.online?(assigns, user)}
                  size={:xs}
                />
                <Text><%= user.username %></Text>
                <Spacer />
                <Image systemName="xmark" style="foregroundStyle(.tint);" />
              </HStack>
            </Button>
          </HStack>
        </ScrollView>
        <Divider />
      </VStack>
    </Group>
    """
  end
end
