defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}

  alias Lax.Chat
  alias Lax.Messages.Message
  alias Lax.Users

  import LaxWeb.ChatLiveComponents

  def render(assigns) do
    ~H"""
    <.container sidebar_width={sidebar_width(@current_user)}>
      <:sidebar>
        <.sidebar_header />
        <.sidebar>
          <.sidebar_section>
            <.sidebar_subheader>
              Channels
            </.sidebar_subheader>
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              selected={Chat.current?(@chat, channel)}
              phx-click={JS.push("select_channel", value: %{id: channel.id})}
            />
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

      <.chat_header channel={@chat.current_channel.name} />
      <.chat>
        <.message
          :for={message <- @chat.messages}
          username={message.sent_by_user.username}
          time={Message.show_time(message, @current_user.time_zone)}
          message={message.text}
        />
      </.chat>
      <.chat_form
        form={@chat_form}
        channel={@chat.current_channel.name}
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
     |> assign(:chat, Chat.load(socket.assigns.current_user))
     |> put_form()}
  end

  def handle_event("resize", %{"width" => width}, socket) do
    {:ok, user} =
      Users.update_user_ui_settings(socket.assigns.current_user, %{
        channels_sidebar_width: width
      })

    {:noreply, assign(socket, :current_user, user)}
  end

  def handle_event("select_channel", %{"id" => channel_id}, socket) do
    {:noreply, update(socket, :chat, &Chat.select_channel(&1, channel_id))}
  end

  def handle_event("validate", %{"chat" => params}, socket) do
    changeset =
      {%{}, %{message: :string}}
      |> Ecto.Changeset.cast(params, [:message])
      |> Map.put(:action, :validate)

    {:noreply, put_form(socket, changeset)}
  end

  def handle_event("submit", %{"chat" => params}, socket) do
    {:noreply, put_form(socket) |> update(:chat, &Chat.send_message(&1, params))}
  end

  def handle_info({Lax.Messages, {:new_message, message}}, socket) do
    {:noreply, update(socket, :chat, &Chat.receive_message(&1, message))}
  end

  ## Helpers

  def put_form(socket, value \\ %{}) do
    assign(socket, :chat_form, to_form(value, as: :chat))
  end

  def sidebar_width(nil), do: 250
  def sidebar_width(current_user), do: current_user.ui_settings.channels_sidebar_width
end
