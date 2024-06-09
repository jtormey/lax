defmodule Lax.Channels do
  import Ecto.Query, warn: false

  alias Lax.Users
  alias Lax.Repo
  alias Lax.Channels.Channel
  alias Lax.Users.Membership

  def get!(id, type) do
    Repo.one!(
      from c in Channel,
        where: c.id == ^id,
        where: c.type == ^type
    )
  end

  def list(:channel = type) do
    Repo.all(
      from c in Channel,
        where: c.type == ^type,
        order_by: c.name
    )
  end

  def create(attrs, opts \\ []) do
    %Channel{}
    |> Channel.changeset(Keyword.get(opts, :type, :channel), attrs)
    |> Repo.insert()
  end

  def create_and_join(user, attrs, opts \\ []) do
    Repo.transaction(fn ->
      case create(attrs, opts) do
        {:ok, channel} ->
          Membership.join_channel!(user, channel)

          opts
          |> Keyword.get(:invite_user_ids, [])
          |> Users.get_all()
          |> Enum.each(&Membership.join_channel!(&1, channel))

          channel

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end
end
