defmodule LaxWeb.ChatLive.ManageChannelsComponent do
  use LaxWeb, :live_component

  alias Lax.Channels
  alias Lax.Users.Membership

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Manage channels
      </.header>

      <div
        :for={channel <- @channels}
        class="w-full flex gap-4 items-center border-b border-zinc-700 py-4"
      >
        <div class="flex gap-1 items-center text-white">
          <.icon name="hero-hashtag" class="size-4" />
          <%= channel.name %>
        </div>
        <div class="flex-1" />
        <.button
          :if={channel.id not in @joined_channels}
          variant={:action}
          icon="hero-plus-circle-mini"
          phx-click={JS.push("join", value: %{id: channel.id}, target: @myself)}
        >
          Join
        </.button>
        <.button
          :if={channel.id in @joined_channels}
          class="group"
          phx-click={JS.push("leave", value: %{id: channel.id}, target: @myself)}
        >
          <span class="hidden group-hover:inline-block">Leave</span>
          <span class="inline-block group-hover:hidden">Joined</span>
        </.button>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, :channels, Channels.list(:channel))}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> put_joined_channels()}
  end

  def handle_event("join", %{"id" => channel_id}, socket) do
    channel = Channels.get!(channel_id, :channel)
    Membership.join_channel!(socket.assigns.current_user, channel)

    send(self(), {__MODULE__, :update_channels})

    {:noreply, put_joined_channels(socket)}
  end

  def handle_event("leave", %{"id" => channel_id}, socket) do
    channel = Channels.get!(channel_id, :channel)
    Membership.leave_channel!(socket.assigns.current_user, channel)

    send(self(), {__MODULE__, :update_channels})

    {:noreply, put_joined_channels(socket)}
  end

  def put_joined_channels(socket) do
    joined_channels =
      socket.assigns.current_user
      |> Membership.list_channels(:channel)
      |> Enum.map(& &1.id)
      |> MapSet.new()

    assign(socket, :joined_channels, joined_channels)
  end
end
