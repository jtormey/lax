defmodule Lax.Indicators do
  import Ecto.Query

  alias Lax.Channels.ChannelUser
  alias Lax.Messages.Message
  alias Lax.Repo

  def mark_viewed(nil, _channel_id) do
    :ok
  end

  def mark_viewed(user, channel_id) do
    now = NaiveDateTime.utc_now()

    ChannelUser
    |> Repo.get_by!(channel_id: channel_id, user_id: user.id)
    |> Ecto.Changeset.change(last_viewed_at: NaiveDateTime.truncate(now, :microsecond))
    |> Repo.update!()

    :ok
  end

  def unread_counts_since_last_viewed(nil) do
    %{}
  end

  def unread_counts_since_last_viewed(user) do
    query =
      from m in Message,
        join: cu in ChannelUser,
        on: [channel_id: m.channel_id, user_id: ^user.id],
        select: {m.channel_id, count(m)},
        where: is_nil(cu.last_viewed_at) or m.inserted_at > cu.last_viewed_at,
        where: m.sent_by_user_id != ^user.id,
        group_by: m.channel_id

    query
    |> Repo.all()
    |> Map.new()
    |> IO.inspect()
  end
end
