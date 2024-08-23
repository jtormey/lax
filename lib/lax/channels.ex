defmodule Lax.Channels do
  import Ecto.Query, warn: false

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
          |> Keyword.get(:invite_users, [])
          |> Enum.each(&Membership.join_channel!(&1, channel))

          channel

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def subscribe_to_new_channels(user) do
    Phoenix.PubSub.subscribe(Lax.PubSub, new_channels_topic(user))
  end

  def unsubscribe_from_new_channels(user) do
    Phoenix.PubSub.unsubscribe(Lax.PubSub, new_channels_topic(user))
  end

  def broadcast_new_channel(users, channel) do
    info = {__MODULE__, {:new_channel, channel}}

    for user <- List.wrap(users) do
      Phoenix.PubSub.broadcast(Lax.PubSub, new_channels_topic(user), info)
    end
  end

  def new_channels_topic(%{id: user_id}), do: "new_channel:#{user_id}"
  def new_channels_topic(user_id), do: "new_channel:#{user_id}"
end
