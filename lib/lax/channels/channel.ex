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

  def changeset(channel, :channel, attrs) do
    channel
    |> cast(attrs, [:name])
    |> put_change(:type, :channel)
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-z][\-\_a-z0-9]*$/,
      message: "must consist of lowercase letters, dashes, and underscores only"
    )
    |> unsafe_validate_unique(:name, Lax.Repo)
    |> unique_constraint(:name)
  end

  def changeset(channel, :direct_message, attrs) do
    channel
    |> cast(attrs, [])
    |> put_change(:type, :direct_message)
  end
end
