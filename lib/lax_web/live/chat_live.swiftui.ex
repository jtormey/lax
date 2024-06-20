defmodule LaxWeb.ChatLive.SwiftUI do
  use LaxNative, [:render_component, format: :swiftui]

  def render(assigns, _interface) do
    ~LVN"""
    <.header>
      Chat
      <:actions>
        <.link :if={!@current_user} navigate={~p"/users/register"} class="font-weight-semibold fg-tint">
          Sign up
        </.link>
        <Text :if={@current_user}>
          Welcome <%= @current_user.email %>!
        </Text>
      </:actions>
    </.header>
    """
  end
end
