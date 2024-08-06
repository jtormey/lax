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

  def list_latest_in_channels(channel_ids) do
    window_query =
      from m in Message,
        where: m.channel_id in ^channel_ids,
        select: %{
          message_id: m.id,
          row_number: over(row_number(), :channel)
        },
        windows: [channel: [partition_by: m.channel_id, order_by: [desc: m.inserted_at]]]

    messages_query =
      from m in Message,
        join: t in subquery(window_query),
        on: t.message_id == m.id and t.row_number == 1,
        order_by: [desc: m.inserted_at],
        preload: [:channel, :sent_by_user]

    Repo.all(messages_query)
  end

  def send(channel, sent_by_user, attrs) do
    %Message{}
    |> Map.put(:channel, channel)
    |> Map.put(:sent_by_user, sent_by_user)
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def delete!(id, user) do
    delete_query =
      from Message,
        where: [id: ^id, sent_by_user_id: ^user.id]

    Repo.delete_all(delete_query)
  end

  def subscribe_to_sent_messages(channel) do
    Phoenix.PubSub.subscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def unsubscribe_from_sent_messages(channel) do
    Phoenix.PubSub.unsubscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def broadcast_sent_message(channel, message) do
    info = {__MODULE__, {:sent_message, message}}
    Phoenix.PubSub.broadcast(Lax.PubSub, sent_messages_topic(channel), info)

    with pid when pid != nil <- GenServer.whereis(:apns_default),
         :direct_message <- channel.type do
      users = Repo.preload(channel, :users).users

      for user <- users, user.id != message.sent_by_user_id do
        for device_token <- user.apns_device_token do
          bundle_id = "com.example.Lax"
          message_body = "@#{message.sent_by_user.username}: #{message.text}"

          message_body
          |> Pigeon.APNS.Notification.new(device_token, bundle_id)
          |> Pigeon.APNS.push()
        end
      end
    end
  end

  def broadcast_deleted_message(channel, message_id) do
    info = {__MODULE__, {:deleted_message, {channel.id, message_id}}}
    Phoenix.PubSub.broadcast(Lax.PubSub, sent_messages_topic(channel), info)
  end

  def sent_messages_topic(%{id: channel_id}), do: "channel_messages:#{channel_id}"
  def sent_messages_topic(channel_id), do: "channel_messages:#{channel_id}"
end
