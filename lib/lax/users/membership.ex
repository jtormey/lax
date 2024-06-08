defmodule Lax.Users.Membership do
  import Ecto.Query

  alias Lax.Channels.DefaultChannel
  alias Lax.Repo
  alias Lax.Channels.Channel
  alias Lax.Channels.ChannelUser

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
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        limit: 1,
        order_by: [asc: c.name]

    Repo.one!(query)
  end

  def list_channels(nil, type) do
    Repo.all(
      from c in Channel,
        where: c.type == ^type,
        order_by: [asc: c.name]
    )
  end

  def list_channels(user, type) do
    Repo.all(
      from c in Channel,
        join: u in assoc(c, :users),
        where: u.id == ^user.id,
        where: c.type == ^type,
        order_by: [asc: c.name]
    )
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
