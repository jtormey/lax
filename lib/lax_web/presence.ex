defmodule LaxWeb.Presence do
  use Phoenix.Presence,
    otp_app: :lax,
    pubsub_server: Lax.PubSub

  defmodule Live do
    import Phoenix.Component
    import Phoenix.LiveView

    @presence "online_users"

    def track_online_users(socket) do
      import Phoenix.Component

      if connected?(socket) do
        {:ok, _} =
          LaxWeb.Presence.track(self(), @presence, socket.assigns.current_user.id, %{
            online_at: inspect(System.system_time(:second))
          })

        Phoenix.PubSub.subscribe(Lax.PubSub, @presence)
      end

      socket
      |> assign(:tracked_users, %{})
      |> handle_joins(LaxWeb.Presence.list(@presence))
      |> attach_hook(:presence_tracking, :handle_info, &handle_info/2)
    end

    def online?(assigns, user) do
      Map.has_key?(Map.get(assigns, :tracked_users, %{}), user.id)
    end

    def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
      {:halt,
       socket
       |> handle_leaves(diff.leaves)
       |> handle_joins(diff.joins)}
    end

    defp handle_joins(socket, joins) do
      Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
        update(socket, :tracked_users, &Map.put(&1, user, meta))
      end)
    end

    defp handle_leaves(socket, leaves) do
      Enum.reduce(leaves, socket, fn {user, _}, socket ->
        update(socket, :tracked_users, &Map.delete(&1, user))
      end)
    end
  end
end
