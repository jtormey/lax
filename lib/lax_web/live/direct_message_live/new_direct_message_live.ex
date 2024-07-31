defmodule LaxWeb.DirectMessageLive.NewDirectMessageLive do
  use LaxWeb, :live_view
  use LaxNative, :live_view

  alias Lax.Channels
  alias Lax.Messages
  alias Lax.Users

  import LaxWeb.ChatLive.Components
  import LaxWeb.UserLive.Components

  def render(assigns) do
    ~H"""
    <div class="flex justify-between gap-2 border-b border-zinc-700 p-4">
      <.header>
        New message
      </.header>
    </div>
    <div class="flex-1 relative overflow-y-scroll no-scrollbar px-4">
      <div class="absolute inset-0">
        <div class="flex-1 mx-auto max-w-sm py-16">
          <div
            :for={user <- @users}
            class="w-full flex gap-4 items-center border-b border-zinc-700 py-6"
          >
            <.user_profile
              user={user}
              online={LaxWeb.Presence.Live.online?(assigns, user)}
              size={:md}
            />
            <.username user={user} />
            <div class="flex-1" />
            <.button
              :if={user.id not in @selected_user_ids}
              variant={:action}
              icon="hero-plus-circle-mini"
              phx-click={JS.push("add", value: %{id: user.id})}
            >
              Add
            </.button>
            <.button
              :if={user.id in @selected_user_ids}
              class="group"
              phx-click={JS.push("remove", value: %{id: user.id})}
            >
              <span class="hidden group-hover:inline-block">Remove</span>
              <span class="inline-block group-hover:hidden">Added</span>
            </.button>
          </div>
        </div>
      </div>
    </div>

    <.chat_form
      form={@chat_form}
      placeholder="Start a new message"
      phx-change="validate"
      phx-submit="submit"
    />
    """
  end

  def mount(%{"to_user" => to_user}, session, socket) do
    mount(%{}, Map.put(session, "initial_user_ids", [to_user]), socket)
  end

  def mount(params, session, socket)
      when params == :not_mounted_at_router or socket.assigns._format == "swiftui" do
    current_user =
      if user_token = session["user_token"] do
        Users.get_user_by_session_token(user_token)
      end

    all_users = Users.list_other_users(current_user)

    {:ok,
     socket
     |> assign(:params, %{})
     |> assign(:selected_user_ids, MapSet.new(session["initial_user_ids"] || []))
     |> assign(:current_user, current_user)
     |> assign(:users, all_users)
     |> assign(:filter, "")
     |> assign(:filtered_users, all_users)
     |> handle_form()}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/direct-messages")}
  end

  def handle_event("add", %{"id" => user_id}, socket) do
    {:noreply,
     socket
     |> update(:selected_user_ids, &MapSet.put(&1, user_id))
     |> handle_form()}
  end

  def handle_event("remove", %{"id" => user_id}, socket) do
    {:noreply,
     socket
     |> update(:selected_user_ids, &MapSet.delete(&1, user_id))
     |> handle_form()}
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    {:noreply,
     assign(socket, filter: filter, filtered_users: filter_users(socket.assigns.users, filter))}
  end

  def handle_event("validate", %{"chat" => params}, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> handle_form(:validate)}
  end

  def handle_event("submit", %{"chat" => params}, socket) do
    case Ecto.Changeset.apply_action(changeset(socket, params), :submit) do
      {:ok, %{text: text, user_ids: user_ids}} ->
        {:ok, channel} =
          Channels.create_and_join(
            socket.assigns.current_user,
            %{},
            type: :direct_message,
            invite_user_ids: user_ids
          )

        user_ids = [socket.assigns.current_user | user_ids]
        Channels.broadcast_new_channel(user_ids, channel)

        {:ok, message} = Messages.send(channel, socket.assigns.current_user, %{text: text})
        Messages.broadcast_sent_message(channel, message)

        send(self(), {__MODULE__, {:create_direct_message, channel}})

        socket = push_navigate(socket, to: ~p"/chat/#{channel.id}", replace: true)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_form(socket, changeset)}
    end
  end

  ## Helpers

  def handle_form(socket, action \\ nil) do
    changeset =
      socket
      |> changeset(socket.assigns.params)
      |> Map.put(:action, action)

    put_form(socket, changeset)
  end

  def put_form(socket, value \\ %{}) do
    assign(socket, :chat_form, to_form(value, as: :chat))
  end

  def changeset(socket, params) do
    import Ecto.Changeset

    {%{}, %{text: :string, user_ids: {:array, :string}}}
    |> cast(params, [:text])
    |> put_change(:user_ids, MapSet.to_list(socket.assigns.selected_user_ids))
    |> validate_required([:text])
    |> validate_length(:user_ids, min: 1)
  end

  def filter_users(users, filter) do
    Enum.filter(
      users,
      &(&1.username |> String.downcase() |> String.contains?(String.downcase(filter)))
    )
  end
end
