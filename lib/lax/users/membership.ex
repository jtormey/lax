defmodule Lax.Users.Membership do
  import Ecto.Query

  alias Lax.Channels.DefaultChannel
  alias Lax.Channels.Channel
  alias Lax.Channels.ChannelUser
  alias Lax.Repo

  def get_channel!(id, user, type) do
    Repo.one!(
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.id == ^id,
        where: c.type == ^type
    )
  end

  def get_default_channel(nil) do
    Repo.get_by!(Channel, name: "general", type: :channel)
  end

  def get_default_channel(user) do
    query =
      from c in Channel,
        join: cu in ChannelUser,
        on: [channel_id: c.id, user_id: ^user.id],
        where:
          c.type != :direct_message or
            c.id in subquery(ChannelUser.channels_with_other_users_query(user)),
        order_by: [desc_nulls_last: cu.last_viewed_at, asc: c.name],
        limit: 1

    Repo.one!(query)
  end

  def list_channels(nil, :channel = type) do
    Repo.all(
      from c in Channel,
        where: c.type == ^type,
        order_by: [asc: c.name]
    )
  end

  def list_channels(nil, :direct_message) do
    []
  end

  def list_channels(user, type) do
    query =
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.type == ^type

    query =
      case type do
        :channel ->
          order_by(query, [c], asc: c.name)

        :direct_message ->
          query
          |> where([c], c.id in subquery(ChannelUser.channels_with_other_users_query(user)))
          |> order_by([c], desc: c.inserted_at)
      end

    Repo.all(query)
  end

  def other_users_in_direct_messages(nil) do
    %{}
  end

  def other_users_in_direct_messages(user) do
    own_direct_messages =
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.type == :direct_message

    query =
      from c in subquery(own_direct_messages),
        join: u in assoc(c, :users),
        where: u.id != ^user.id,
        select: %{channel_id: c.id, user: u}

    query
    |> Repo.all()
    |> Enum.group_by(& &1.channel_id, & &1.user)
  end

  def join_channel!(user, channel) do
    Repo.insert!(%ChannelUser{
      channel: channel,
      user: user
    })
  end

  def leave_channel!(user, channel) do
    delete_query =
      from ChannelUser,
        where: [channel_id: ^channel.id, user_id: ^user.id]

    Repo.delete_all(delete_query)
  end

  def join_default_channels!(user) do
    channels =
      Repo.all(
        from d in DefaultChannel,
          join: c in assoc(d, :channel),
          select: c
      )

    Enum.each(channels, &join_channel!(user, &1))
  end
end
