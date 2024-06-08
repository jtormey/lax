defmodule Lax.Chat do
  alias Lax.Messages
  alias Lax.Channels.ChannelUser
  alias Lax.Channels.Channel
  alias Lax.Repo
  alias Lax.Users.Membership

  defstruct [:user, :channels, :current_channel, :messages]

  def load(user) do
    %__MODULE__{
      user: user,
      channels: Membership.list_channels(user, :channel),
      current_channel: Membership.get_default_channel(user)
    }
    |> subscribe_messages()
    |> put_messages()
  end

  def current?(chat, channel) do
    chat.current_channel.id == channel.id
  end

  def select_channel(chat, channel_id) do
    channel =
      if user = chat.user do
        channel_user =
          Repo.get_by!(
            ChannelUser,
            channel_id: channel_id,
            user_id: user.id
          )

        channel_user
        |> Ecto.Changeset.change(last_viewed_at: DateTime.truncate(DateTime.utc_now(), :second))
        |> Repo.update!()

        Repo.get!(Channel, channel_id)
      else
        Repo.get!(Channel, channel_id)
      end

    chat
    |> unsubscribe_messages()
    |> Map.put(:current_channel, channel)
    |> subscribe_messages()
    |> put_messages()
  end

  def send_message(chat, attrs) do
    if chat.user == nil, do: raise("no user")

    {:ok, message} = Messages.send(chat.current_channel, chat.user, attrs)
    Messages.broadcast_sent_message(chat.current_channel, message)

    chat
  end

  def receive_message(chat, message) do
    if chat.current_channel.id == message.channel_id do
      %{chat | messages: [message | chat.messages]}
    else
      chat
    end
  end

  ## Private

  defp subscribe_messages(chat) do
    Messages.subscribe_to_sent_messages(chat.current_channel)
    chat
  end

  defp unsubscribe_messages(chat) do
    Messages.unsubscribe_from_sent_messages(chat.current_channel)
    chat
  end

  defp put_messages(chat) do
    %{chat | messages: Messages.list(chat.current_channel)}
  end
end
