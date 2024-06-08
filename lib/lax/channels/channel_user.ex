defmodule Lax.Channels.ChannelUser do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id

  schema "channels_users" do
    field :last_viewed_at, :utc_datetime

    belongs_to :channel, Lax.Channels.Channel, primary_key: true
    belongs_to :user, Lax.Users.User, primary_key: true

    timestamps(updated_at: false)
  end
end
