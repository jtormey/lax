defmodule Lax.Messages.LinkPreview.PubSub do
  @moduledoc """
  PubSub helpers for link_preview messages.

  """

  alias Lax.Messages.LinkPreview

  @doc """
  Subscribes to messages for all link_previews that are associated with
  the given resource.

  """
  def subscribe_link_preview({:ok, subject}) do
    {:ok, subscribe_link_preview(subject)}
  end

  def subscribe_link_preview({:error, reason}) do
    {:error, reason}
  end

  def subscribe_link_preview(resource = %_ResourceSchema{}) do
    topic = link_preview_topic(resource)
    Phoenix.PubSub.subscribe(Lax.PubSub, topic)
    resource
  end

  @doc """
  Broadcasts a message for a link_preview on the topic for the
  associated resource.

  """
  def broadcast_link_preview({:ok, subject}, message) do
    {:ok, broadcast_link_preview(subject, message)}
  end

  def broadcast_link_preview({:error, reason}, _message) do
    {:error, reason}
  end

  def broadcast_link_preview(link_preview = %LinkPreview{}, message) do
    topic = link_preview_topic(link_preview)
    Phoenix.PubSub.broadcast(Lax.PubSub, topic, {:link_preview, message, link_preview})
    link_preview
  end

  defp link_preview_topic(link_preview = %LinkPreview{}) do
    "link_previews:#{link_preview.resource_id}"
  end

  defp link_preview_topic(%_ResourceSchema{id: resource_id}) do
    "link_previews:#{resource_id}"
  end
end
