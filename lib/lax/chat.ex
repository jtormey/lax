defmodule Lax.Chat do
  alias Lax.Channels.Channel
  alias Lax.Indicators
  alias Lax.Messages
  alias Lax.Repo
  alias Lax.Users.Membership

  defstruct [:user, :channels, :current_channel, :messages, :unread_counts]

  def load(user) do
    %__MODULE__{
      user: user,
      channels: Membership.list_channels(user, :channel),
      current_channel: Membership.get_default_channel(user)
    }
    |> tap(&Indicators.mark_viewed(user, &1.current_channel.id))
    |> subscribe_messages()
    |> put_messages()
    |> put_unread_counts()
  end

  def current?(chat, channel) do
    chat.current_channel.id == channel.id
  end

  def has_activity?(chat, channel) do
    Map.has_key?(chat.unread_counts, channel.id)
  end

  def unread_count(chat, channel) do
    Map.get(chat.unread_counts, channel.id, 0)
  end

  def select_channel(chat, channel_id) do
    if user = chat.user do
      Indicators.mark_viewed(user, channel_id)
    end

    chat
    |> Map.put(:current_channel, Repo.get!(Channel, channel_id))
    |> put_messages()
    |> put_unread_counts()
  end

  def send_message(chat, attrs) do
    if chat.user == nil, do: raise("no user")

    {:ok, message} = Messages.send(chat.current_channel, chat.user, attrs)
    Messages.broadcast_sent_message(chat.current_channel, message)

    chat
  end

  def receive_message(chat, message) do
    if chat.current_channel.id == message.channel_id do
      Indicators.mark_viewed(chat.user, message.channel_id)
      %{chat | messages: [message | chat.messages]}
    else
      chat
    end
    |> put_unread_counts()
  end

  ## Private

  defp subscribe_messages(chat) do
    for channel <- chat.channels do
      Messages.subscribe_to_sent_messages(channel)
    end

    chat
  end

  defp put_messages(chat) do
    %{chat | messages: Messages.list(chat.current_channel)}
  end

  defp put_unread_counts(chat) do
    %{chat | unread_counts: Indicators.unread_counts_since_last_viewed(chat.user)}
  end
end
