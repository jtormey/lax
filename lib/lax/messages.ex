defmodule Lax.Messages do
  import Ecto.Query, warn: false

  alias Lax.Repo
  alias Lax.Messages.Message

  def list(channel) do
    query =
      from m in Message,
        where: m.channel_id == ^channel.id,
        order_by: [desc: :inserted_at],
        preload: [:sent_by_user]

    Repo.all(query)
  end

  def list_latest_in_channels(channel_ids) do
    window_query =
      from m in Message,
        where: m.channel_id in ^channel_ids,
        select: %{
          message_id: m.id,
          row_number: over(row_number(), :channel)
        },
        windows: [channel: [partition_by: m.channel_id, order_by: [desc: m.inserted_at]]]

    messages_query =
      from m in Message,
        join: t in subquery(window_query),
        on: t.message_id == m.id and t.row_number == 1,
        order_by: [desc: m.inserted_at],
        preload: [:channel, :sent_by_user]

    Repo.all(messages_query)
  end

  def send(channel, sent_by_user, attrs) do
    %Message{}
    |> Map.put(:channel, channel)
    |> Map.put(:sent_by_user, sent_by_user)
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def delete!(id, user) do
    delete_query =
      from Message,
        where: [id: ^id, sent_by_user_id: ^user.id]

    Repo.delete_all(delete_query)
  end

  def subscribe_to_sent_messages(channel) do
    Phoenix.PubSub.subscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def unsubscribe_from_sent_messages(channel) do
    Phoenix.PubSub.unsubscribe(Lax.PubSub, sent_messages_topic(channel))
  end

  def broadcast_sent_message(channel, message) do
    info = {__MODULE__, {:sent_message, message}}
    Phoenix.PubSub.broadcast(Lax.PubSub, sent_messages_topic(channel), info)

    with pid when pid != nil <- GenServer.whereis(:apns_default),
         :direct_message <- channel.type do
      users = Repo.preload(channel, :users).users
      sender = message.sent_by_user
      title = "@#{sender.username}"

      for user <- users, user.id != message.sent_by_user_id do
        for device_token <- user.apns_device_token do
          bundle_id = "com.example.Lax"

          subtitle =
            case Enum.filter(users, &(&1.id != user.id and &1.id != sender.id)) do
              [] ->
                nil

              users ->
                users
                |> Enum.reduce({"To You", length(users)}, fn
                  user, {"", l} ->
                    {"@#{user.username}", l - 1}

                  user, {acc, 1} ->
                    {"#{acc} & @#{user.username}", 0}

                  user, {acc, l} ->
                    {"#{acc}, @#{user.username}", l - 1}
                end)
                |> elem(0)
            end

          Task.Supervisor.start_child(Lax.PigeonSupervisor, fn ->
            notification =
              Pigeon.APNS.Notification.new("", device_token, bundle_id)
              |> Pigeon.APNS.Notification.put_custom(%{
                "aps" => %{
                  "alert" => %{
                    "title" => title,
                    "subtitle" => subtitle,
                    "body" => message.text
                  },
                  "thread-id" => channel.id
                },
                "navigate" => channel.id
              })

            Pigeon.APNS.push(notification)
          end)
        end
      end
    end
  end

  def broadcast_deleted_message(channel, message_id) do
    info = {__MODULE__, {:deleted_message, {channel.id, message_id}}}
    Phoenix.PubSub.broadcast(Lax.PubSub, sent_messages_topic(channel), info)
  end

  def sent_messages_topic(%{id: channel_id}), do: "channel_messages:#{channel_id}"
  def sent_messages_topic(channel_id), do: "channel_messages:#{channel_id}"

  alias Lax.Messages.LinkPreview

  @doc """
  Returns the list of link_preview for a particular resource.

  ## Examples

    iex> list_link_previews(resource)
    [%LinkPreview{}, %LinkPreview{}]

  """
  def list_link_previews(resource = %_Schema{}) do
    Repo.all(
      from l in LinkPreview,
        where: [resource_id: ^resource.id]
    )
  end

  @doc """
  Creates a new link_preview for a resource in a loading state.

  ## Examples

    iex> create_link_preview(link, resource)
    %LinkPreview{}

  """
  def create_link_preview(link, resource = %_Schema{}) do
    %LinkPreview{}
    |> LinkPreview.changeset(%{link: link, resource_id: resource.id})
    |> Repo.insert()
    |> LinkPreview.PubSub.broadcast_link_preview(:created)
  end

  @doc """
  Updates a link_preview when it has been successfully loaded.

  ## Examples

    iex> update_link_preview_loaded(link_preview, attrs)
    %LinkPreview{}

  """
  def update_link_preview_loaded(link_preview = %LinkPreview{}, attrs) do
    link_preview
    |> LinkPreview.loaded_changeset(attrs)
    |> Repo.update()
    |> LinkPreview.PubSub.broadcast_link_preview(:updated)
  end

  @doc """
  Updates a link_preview when it has failed to load.

  ## Examples

    iex> update_link_preview_failed(link_preview)
    %LinkPreview{}

  """
  def update_link_preview_failed(link_preview = %LinkPreview{}) do
    link_preview
    |> LinkPreview.failed_changeset(%{})
    |> Repo.update()
    |> LinkPreview.PubSub.broadcast_link_preview(:updated)
  end

  @doc """
  Deletes a link_preview.

  ## Examples

    iex> delete_link_preview(link_preview)
    %LinkPreview{}

  """
  def delete_link_preview(link_preview = %LinkPreview{}) do
    link_preview
    |> Repo.delete()
    |> LinkPreview.PubSub.broadcast_link_preview(:deleted)
  end

  @doc """
  Deletes every link_preview for a resource, with the option to delete only
  those matching specific links.

  ## Examples

    iex> delete_link_previews(resource)
    %ResourceSchema{}

    iex> delete_link_previews(resource, links: ["http://example.com/"])
    %ResourceSchema{}

  """
  def delete_link_previews(resource = %_Schema{}, opts \\ []) do
    q = from l in LinkPreview, where: [resource_id: ^resource.id]
    q = if links = opts[:links], do: where(q, [l], l.link in ^links), else: q
    Repo.delete_all(q)
    resource
  end
end
