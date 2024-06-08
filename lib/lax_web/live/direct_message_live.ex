defmodule LaxWeb.DirectMessageLive do
  use LaxWeb, {:live_view, layout: :chat}

  alias Lax.Users

  import LaxWeb.ChatLive.Components
  import LaxWeb.DirectMessageLive.Components

  def render(assigns) do
    ~H"""
    <.container
      sidebar_width={sidebar_width(@current_user)}
      sidebar_min_width={384}
      sidebar_max_width={1024}
    >
      <:sidebar>
        <.sidebar_header title="Direct messages" />
      </:sidebar>

      <.render_action {assigns} />
    </.container>
    """
  end

  def render_action(%{live_action: :index} = assigns) do
    ~H"""
    <.empty_state />
    """
  end

  def render_action(%{live_action: :new} = assigns) do
    ~H"""
    <.live_component
      id="new_direct_message"
      module={__MODULE__.NewDirectMessageComponent}
      current_user={@current_user}
    />
    """
  end

  def render_action(%{live_action: :chat} = assigns) do
    ~H"""

    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :direct_messages)}
  end

  def handle_event("resize", %{"width" => width}, socket) do
    {:ok, user} =
      Users.update_user_ui_settings(socket.assigns.current_user, %{
        direct_messages_sidebar_width: width
      })

    {:noreply, assign(socket, :current_user, user)}
  end

  ## Helpers

  def sidebar_width(nil), do: 500
  def sidebar_width(current_user), do: current_user.ui_settings.direct_messages_sidebar_width
end
