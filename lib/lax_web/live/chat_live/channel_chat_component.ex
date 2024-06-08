defmodule LaxWeb.ChatLive.ChannelChatComponent do
  use LaxWeb, :live_component

  alias Lax.Chat

  import LaxWeb.ChatLive.Components

  def render(assigns) do
    ~H"""
    <div>
      <.chat_form
        form={@chat_form}
        placeholder={placeholder(@chat.current_channel)}
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
     |> handle_form()}
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

  def placeholder(%{type: :channel} = channel), do: "Message #{channel.name}"
  def placeholder(%{type: :direct_message}), do: "Message group"
end
