defmodule Lax.Chat do
  alias Lax.Repo
  alias Lax.Channels
  alias Lax.Indicators
  alias Lax.Messages
  alias Lax.Users.Membership

  defstruct [
    :user,
    # Channel records of type :channel, in order of asc: :name
    :channels,
    # Channel records of type :direct_message, in order of desc: :inserted_at
    :direct_messages,
    # Map of users associated with direct messages, keyed by channel_id
    :direct_messages_other_users,
    # Current channel, of any type
    :current_channel,
    # Current messages
    :messages,
    # List of latest messages sent in :direct_message channels
    :latest_message_in_direct_messages,
    # Map of unread message countes, keyed by channel_id
    :unread_counts,
    # MapSet of channels that have already been subscribed to
    :subscribed_channels
  ]

  def load(user, channel \\ nil) do
    %__MODULE__{
      user: user,
      current_channel: channel || Membership.get_default_channel(user),
      subscribed_channels: MapSet.new()
    }
    |> tap(&Indicators.mark_viewed(user, &1.current_channel.id))
    |> put_channels()
    |> put_messages()
    |> put_latest_message_in_direct_messages()
    |> put_unread_counts()
    |> subscribe_channels()
    |> subscribe_messages()
  end

  def current?(chat, channel) do
    chat.current_channel && chat.current_channel.id == channel.id
  end

  def has_activity?(chat, channel) do
    Map.has_key?(chat.unread_counts, channel.id)
  end

  def unread_count(chat, channel) do
    Map.get(chat.unread_counts, channel.id, 0)
  end

  def direct_message_users(chat, channel) do
    Map.fetch!(chat.direct_messages_other_users, channel.id)
  end

  def latest_message(chat, channel) do
    Map.fetch!(chat.latest_message_in_direct_messages, channel.id)
  end

  def select_channel(chat, nil) do
    chat
    |> Map.put(:current_channel, nil)
    |> put_messages()
  end

  def select_channel(chat, channel_id) do
    if user = chat.user do
      Indicators.mark_viewed(user, channel_id)
    end

    if channel = Enum.find(chat.channels ++ chat.direct_messages, &(&1.id == channel_id)) do
      {:ok,
       chat
       |> Map.put(:current_channel, channel)
       |> put_messages()
       |> put_unread_counts()}
    else
      {:error, :channel_not_found}
    end
  end

  def send_message(chat, attrs) do
    if chat.user == nil, do: raise("User required to send message")

    {:ok, message} = Messages.send(chat.current_channel, chat.user, attrs)
    message = Repo.preload(message, :link_previews)
    Messages.broadcast_sent_message(chat.current_channel, message)

    chat
  end

  def delete_message(chat, message_id) do
    if chat.user == nil, do: raise("User required to delete message")

    Messages.delete!(message_id, chat.user)
    Messages.broadcast_deleted_message(chat.current_channel, message_id)

    chat
  end

  def reload_channels(chat) do
    chat
    |> put_channels()
    |> put_latest_message_in_direct_messages()
    |> put_unread_counts()
    |> subscribe_messages()
  end

  def reload_messages(chat) do
    chat
    |> put_messages()
    |> put_latest_message_in_direct_messages()
    |> put_unread_counts()
  end

  def receive_sent_message(chat, message) do
    if chat.current_channel && chat.current_channel.id == message.channel_id do
      Indicators.mark_viewed(chat.user, message.channel_id)
      Messages.LinkPreview.PubSub.subscribe_link_preview(message)
      %{chat | messages: [message | chat.messages]}
    else
      chat
    end
    |> put_latest_message_in_direct_messages()
    |> put_unread_counts()
  end

  def receive_link_preview(chat, %{resource_id: resource_id}) do
    if chat.current_channel do
      messages =
        Enum.map(chat.messages, fn
          %{id: ^resource_id} = message -> Repo.preload(message, :link_previews, force: true)
          message -> message
        end)

      %{chat | messages: messages}
    else
      chat
    end
  end

  def receive_deleted_message(chat, {channel_id, message_id}) do
    if chat.current_channel && chat.current_channel.id == channel_id do
      Indicators.mark_viewed(chat.user, channel_id)
      %{chat | messages: Enum.reject(chat.messages, &(&1.id == message_id))}
    else
      chat
    end
    |> put_latest_message_in_direct_messages()
    |> put_unread_counts()
  end

  ## Private

  defp subscribe_channels(chat) do
    Channels.subscribe_to_new_channels(chat.user)

    chat
  end

  defp subscribe_messages(chat) do
    channel_ids = MapSet.new(chat.channels ++ chat.direct_messages, & &1.id)

    for channel_id <- MapSet.difference(channel_ids, chat.subscribed_channels) do
      Messages.subscribe_to_sent_messages(channel_id)
    end

    for channel_id <- MapSet.difference(chat.subscribed_channels, channel_ids) do
      Messages.unsubscribe_from_sent_messages(channel_id)
    end

    Map.put(chat, :subscribed_channels, channel_ids)
  end

  defp put_channels(chat) do
    chat =
      %{
        chat
        | channels: Membership.list_channels(chat.user, :channel),
          direct_messages: Membership.list_channels(chat.user, :direct_message),
          direct_messages_other_users: Membership.other_users_in_direct_messages(chat.user)
      }

    if chat.user && chat.current_channel &&
         chat.current_channel.id not in Enum.map(chat.channels, & &1.id) do
      %{chat | current_channel: Membership.get_default_channel(chat.user)}
    else
      chat
    end
  end

  defp put_messages(chat) do
    if channel = chat.current_channel do
      %{chat | messages: Messages.list(channel)}
    else
      %{chat | messages: []}
    end
  end

  defp put_latest_message_in_direct_messages(chat) do
    direct_message_ids = Enum.map(chat.direct_messages, & &1.id)
    latest = Messages.list_latest_in_channels(direct_message_ids)

    %{chat | latest_message_in_direct_messages: latest}
  end

  defp put_unread_counts(chat) do
    %{chat | unread_counts: Indicators.unread_counts_since_last_viewed(chat.user)}
  end
end
