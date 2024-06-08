defmodule Lax.Channels.DefaultChannel do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id

  schema "default_channels" do
    belongs_to :channel, Lax.Channels.Channel, primary_key: true
  end
end
