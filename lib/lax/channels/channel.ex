defmodule Lax.Channels.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "channels" do
    field :name, :string
    field :type, Ecto.Enum, values: [:channel, :direct_message]

    many_to_many :users, Lax.Users.User, join_through: Lax.Channels.ChannelUser

    timestamps()
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[\-\_a-z0-9]+$/)
  end
end
