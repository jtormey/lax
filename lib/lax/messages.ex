defmodule Lax.Messages do
  import Ecto.Query, warn: false

  alias Lax.Repo
  alias Lax.Messages.Message

  def list(channel) do
    query =
      from m in Message,
        where: m.channel_id == ^channel.id,
        order_by: [desc: :inserted_at],
        preload: [:sent_by_user]

    Repo.all(query)
  end

  def send(channel, sent_by_user, attrs) do
    %Message{}
    |> Map.put(:channel, channel)
    |> Map.put(:sent_by_user, sent_by_user)
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def subscribe_to_sent_messages(channel) do
    Phoenix.PubSub.subscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def unsubscribe_from_sent_messages(channel) do
    Phoenix.PubSub.unsubscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def broadcast_sent_message(channel, message) do
    info = {__MODULE__, {:new_message, message}}
    Phoenix.PubSub.broadcast(Lax.PubSub, sent_messages_topic(channel), info)
  end

  def sent_messages_topic(channel) do
    "channel_messages:#{channel.id}"
  end
end
