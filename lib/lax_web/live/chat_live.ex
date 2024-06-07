defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}

  def render(assigns) do
    ~H"""
    <.header>
      Chat
    </.header>
    """
  end
end
