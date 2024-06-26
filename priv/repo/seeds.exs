# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lax.Repo.insert!(%Lax.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

unless Lax.Repo.exists?(Lax.Channels.DefaultChannel) do
  {:ok, channel} = Lax.Channels.create(%{name: "general"})
  Lax.Repo.insert!(%Lax.Channels.DefaultChannel{channel: channel})

  {:ok, channel} = Lax.Channels.create(%{name: "random"})
  Lax.Repo.insert!(%Lax.Channels.DefaultChannel{channel: channel})
end
