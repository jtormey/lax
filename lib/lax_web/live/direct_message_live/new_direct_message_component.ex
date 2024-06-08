defmodule LaxWeb.DirectMessageLive.NewDirectMessageComponent do
  use LaxWeb, :live_component

  alias Lax.Channels
  alias Lax.Messages
  alias Lax.Users

  import LaxWeb.ChatLive.Components
  import LaxWeb.UserLive.Components

  def render(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col">
      <div class="flex justify-between gap-2 border-b border-zinc-700 p-4">
        <.header>
          New message
        </.header>
      </div>

      <div class="flex-1 relative overflow-y-scroll px-4">
        <div class="flex-1 mx-auto max-w-sm py-16">
          <div
            :for={user <- @users}
            class="w-full flex gap-4 items-center border-b border-zinc-700 py-6"
          >
            <.user_profile user={user} size={:md} />
            <.username user={user} />
            <div class="flex-1" />
            <.button
              :if={user.id not in @selected_user_ids}
              variant={:action}
              icon="hero-plus-circle-mini"
              phx-click={JS.push("add", value: %{id: user.id}, target: @myself)}
            >
              Add
            </.button>
            <.button
              :if={user.id in @selected_user_ids}
              class="group"
              phx-click={JS.push("remove", value: %{id: user.id}, target: @myself)}
            >
              <span class="hidden group-hover:inline-block">Remove</span>
              <span class="inline-block group-hover:hidden">Added</span>
            </.button>
          </div>
        </div>
      </div>

      <.chat_form
        form={@chat_form}
        placeholder="Start a new message"
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      />
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign(:params, %{})
     |> assign(:selected_user_ids, MapSet.new())
     |> handle_form()}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:users, Users.list_other_users(assigns.current_user))}
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

        {:ok, _message} = Messages.send(channel, socket.assigns.current_user, %{text: text})

        {:noreply, push_patch(socket, to: ~p"/direct-messages/#{channel}")}

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
end
