defmodule LaxWeb.ChatLive do
  alias Lax.Users
  use LaxWeb, {:live_view, layout: :chat}

  import LaxWeb.ChatLiveComponents

  def render(assigns) do
    ~H"""
    <.container sidebar_width={
      if user = @current_user, do: user.ui_settings.channels_sidebar_width, else: 250
    }>
      <:sidebar>
        <.sidebar_header />
        <.sidebar>
          <.sidebar_section>
            <.sidebar_subheader>
              Channels
            </.sidebar_subheader>
            <.channel_item name="office-austin" />
            <.channel_item name="office-new-york" selected />
            <.channel_item name="office-sf" active />
          </.sidebar_section>

          <.sidebar_section>
            <.sidebar_subheader>
              Direct messages
            </.sidebar_subheader>
            <.dm_item username="justin" />
            <.dm_item username="blaine" online active />
            <.dm_item username="ramon" unread_count={3} />
          </.sidebar_section>
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

  def handle_event("resize", %{"width" => width}, socket) do
    {:ok, user} =
      Users.update_user_ui_settings(socket.assigns.current_user, %{
        channels_sidebar_width: width
      })

    {:noreply, assign(socket, :current_user, user)}
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
