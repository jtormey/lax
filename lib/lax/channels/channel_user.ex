defmodule Lax.Channels.ChannelUser do
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  @foreign_key_type :binary_id

  schema "channels_users" do
    field :last_viewed_at, :naive_datetime_usec

    belongs_to :channel, Lax.Channels.Channel, primary_key: true
    belongs_to :user, Lax.Users.User, primary_key: true

    timestamps(updated_at: false)
  end

  def channels_with_other_users_query(user) do
    __MODULE__
    |> join(:inner, [cu], u in assoc(cu, :user))
    |> where([cu, u], u.id != ^user.id and is_nil(u.deleted_at))
    |> select([cu], cu.channel_id)
  end
end
