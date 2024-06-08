defmodule Lax.Channels do
  import Ecto.Query, warn: false

  alias Lax.Repo
  alias Lax.Channels.Channel
  alias Lax.Users.Membership

  def create(attrs) do
    %Channel{type: :channel}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  def create_and_join(user, attrs) do
    Repo.transaction(fn ->
      case create(attrs) do
        {:ok, channel} ->
          Membership.join_channel!(user, channel)
          {:ok, channel}

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end
end
