defmodule LaxWeb.ChatLive do
  use LaxWeb, {:live_view, layout: :chat}

  alias Lax.Chat
  alias Lax.Messages.Message
  alias Lax.Users
  alias __MODULE__.ChannelFormComponent

  import LaxWeb.ChatLiveComponents

  def render(assigns) do
    ~H"""
    <.container sidebar_width={sidebar_width(@current_user)}>
      <:sidebar>
        <.sidebar_header title="Workspace" />
        <.sidebar>
          <.sidebar_section>
            <.sidebar_subheader>
              Channels
              <:actions>
                <.icon_button icon="hero-plus" phx-click="show_new_channel" />
              </:actions>
            </.sidebar_subheader>
            <.channel_item
              :for={channel <- @chat.channels}
              name={channel.name}
              selected={Chat.current?(@chat, channel)}
              active={Chat.has_activity?(@chat, channel)}
              phx-click={JS.push("select_channel", value: %{id: channel.id})}
            />
          </.sidebar_section>

          <.sidebar_section>
            <.sidebar_subheader>
              Direct messages
              <:actions>
                <.icon_button icon="hero-plus" phx-click={JS.navigate(~p"/direct-messages/new")} />
              </:actions>
            </.sidebar_subheader>
            <.direct_message_item
              :for={channel <- @chat.direct_messages}
              users={Chat.direct_message_users(@chat, channel)}
              selected={Chat.current?(@chat, channel)}
              active={Chat.has_activity?(@chat, channel)}
              unread_count={Chat.unread_count(@chat, channel)}
              phx-click={JS.push("select_channel", value: %{id: channel.id})}
            />
          </.sidebar_section>
        </.sidebar>
      </:sidebar>

      <.chat_header channel={@chat.current_channel.name} />
      <.chat>
        <.message
          :for={message <- @chat.messages}
          user={message.sent_by_user}
          time={Message.show_time(message, @current_user && @current_user.time_zone)}
          message={message.text}
        />
      </.chat>
      <.chat_form
        form={@chat_form}
        placeholder={"Message ##{@chat.current_channel.name}"}
        phx-change="validate"
        phx-submit="submit"
      />
    </.container>

    <.modal :if={@modal == :new_channel} id="new_channel_modal" show on_cancel={JS.push("hide_modal")}>
      <.live_component
        id="new_channel_form"
        module={__MODULE__.ChannelFormComponent}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:domain, :home)
     |> assign(:modal, nil)
     |> assign(:chat, Chat.load(socket.assigns.current_user))
     |> handle_form()}
  end

  def handle_event("resize", %{"width" => width}, socket) do
    {:ok, user} =
      Users.update_user_ui_settings(socket.assigns.current_user, %{
        channels_sidebar_width: width
      })

    {:noreply, assign(socket, :current_user, user)}
  end

  def handle_event("show_new_channel", _params, socket) do
    {:noreply, assign(socket, :modal, :new_channel)}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, :modal, nil)}
  end

  def handle_event("select_channel", %{"id" => channel_id}, socket) do
    {:noreply, update(socket, :chat, &Chat.select_channel(&1, channel_id))}
  end

  def handle_event("validate", %{"chat" => params}, socket) do
    {:noreply, handle_form(socket, params, :validate)}
  end

  def handle_event("submit", %{"chat" => params}, socket) do
    case Ecto.Changeset.apply_action(changeset(params), :submit) do
      {:ok, attrs} ->
        {:noreply,
         socket
         |> handle_form()
         |> update(:chat, &Chat.send_message(&1, attrs))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_form(socket, changeset)}
    end
  end

  def handle_info({ChannelFormComponent, {:create_channel, channel}}, socket) do
    {:noreply,
     socket
     |> assign(:chat, Chat.load(socket.assigns.current_user, channel))
     |> assign(:modal, nil)}
  end

  def handle_info({Lax.Messages, {:new_message, message}}, socket) do
    {:noreply, update(socket, :chat, &Chat.receive_message(&1, message))}
  end

  ## Helpers

  def handle_form(socket, params \\ %{}, action \\ nil) do
    changeset =
      params
      |> changeset()
      |> Map.put(:action, action)

    put_form(socket, changeset)
  end

  def put_form(socket, value \\ %{}) do
    assign(socket, :chat_form, to_form(value, as: :chat))
  end

  def changeset(params) do
    import Ecto.Changeset

    {%{}, %{text: :string}}
    |> cast(params, [:text])
    |> validate_required([:text])
  end

  def sidebar_width(nil), do: 250
  def sidebar_width(current_user), do: current_user.ui_settings.channels_sidebar_width
end
