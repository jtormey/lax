defmodule LaxWeb.DirectMessageLive.NewDirectMessageLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  import LaxWeb.DirectMessageLive.Components.SwiftUI
  import LaxWeb.UserLive.Components.SwiftUI
  import LaxWeb.ChatLive.Components.SwiftUI

  def render(assigns, _interface) do
    ~LVN"""
    <Group
      style={[
        ~s[searchable(text: attr("filter"), placement: .navigationBarDrawer(displayMode: .always), prompt: "Add users")],
        "safeAreaInset(edge: .bottom, content: :chat_form)",
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
        <Section>
          <Text template="header">Group</Text>
          <Button
            :for={user <- Enum.map(@selected_user_ids, fn id -> Enum.find(@users, &(&1.id == id)) end)}
            phx-click="remove"
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
              <Image systemName="minus" style="foregroundStyle(.tint);" />
            </HStack>
          </Button>
        </Section>
        <Section>
          <Text template="header">More Users</Text>
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
        </Section>
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
    </Group>
    """
  end
end
