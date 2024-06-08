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
    query =
      from c in Channel,
        limit: 1,
        order_by: [asc: c.name]

    Repo.one!(query)
  end

  def get_default_channel(user) do
    query =
      from c in Channel,
        join: cu in ChannelUser,
        on: [channel_id: c.id, user_id: ^user.id],
        order_by: [desc: cu.last_viewed_at, asc: c.name],
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

  def list_channels(user, :channel = type) do
    Repo.all(
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.type == ^type,
        order_by: [asc: c.name]
    )
  end

  def list_channels(user, :direct_message = type) do
    own_direct_messages =
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.type == ^type

    Repo.all(
      from c in subquery(own_direct_messages),
        join: u in assoc(c, :users),
        where: u.id != ^user.id,
        order_by: [asc: u.username]
    )
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
