defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}

  import LaxWeb.ChatLiveComponents

  def render(assigns) do
    ~H"""
    <.container sidebar_width={256}>
      <:sidebar>
        <.sidebar_header />
        <.sidebar>
          <.sidebar_subheader>
            Channels
          </.sidebar_subheader>
          <.channel_item name="office-austin" />
          <.channel_item name="office-new-york" selected />
          <.channel_item name="office-sf" active />
        </.sidebar>
      </:sidebar>

      <.chat_header channel="office-new-york" />
      <.chat>
        <.message username="justin" time="2:49 PM" message="hello world" />
      </.chat>
      <.chat_form
        form={@chat_form}
        channel="office-new-york"
        phx-change="validate"
        phx-submit="submit"
      />
    </.container>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :home)
     |> put_form()}
  end

  def handle_event("validate", %{"chat" => params}, socket) do
    changeset =
      {%{}, %{message: :string}}
      |> Ecto.Changeset.cast(params, [:message])
      |> Map.put(:action, :validate)

    {:noreply, put_form(socket, changeset)}
  end

  def handle_event("submit", %{"chat" => params}, socket) do
    IO.inspect(params)
    {:noreply, put_form(socket)}
  end

  def put_form(socket, value \\ %{}) do
    assign(socket, :chat_form, to_form(value, as: :chat))
  end
end
