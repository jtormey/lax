defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}

  import LaxWeb.ChatLiveComponents

  def render(assigns) do
    ~H"""
    <.container sidebar_width={256}>
      <:sidebar>
        <.sidebar_header />
        <.sidebar>
          <.chat_header>
            Channels
          </.chat_header>
          <.channel_item name="office-austin" />
          <.channel_item name="office-new-york" selected />
          <.channel_item name="office-sf" active />
        </.sidebar>
      </:sidebar>
    </.container>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :domain, :home)}
  end
end
