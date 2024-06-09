defmodule LaxWeb.ChatLive.ChannelFormComponent do
  use LaxWeb, :live_component

  alias Lax.Channels
  alias Lax.Channels.Channel

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Create a channel
      </.header>

      <.simple_form for={@form} phx-change="validate" phx-submit="submit" phx-target={@myself}>
        <.input field={@form[:name]} label="Name" autocomplete="off" />
        <:actions>
          <.button type="submit">Submit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, put_form(socket)}
  end

  def handle_event("validate", %{"channel" => params}, socket) do
    changeset =
      %Channel{}
      |> Channel.changeset(:channel, params)
      |> Map.put(:action, :validate)

    {:noreply, put_form(socket, changeset)}
  end

  def handle_event("submit", %{"channel" => params}, socket) do
    case Channels.create_and_join(socket.assigns.current_user, params) do
      {:ok, channel} ->
        send(self(), {__MODULE__, {:create_channel, channel}})
        Channels.broadcast_new_channel(socket.assigns.current_user, channel)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_form(socket, changeset)}
    end
  end

  def put_form(socket, value \\ %{}) do
    assign(socket, :form, to_form(value, as: :channel))
  end
end
