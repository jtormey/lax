defmodule Lax.Messages.LinkPreview do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  schema "link_previews" do
    field :link, :string, primary_key: true
    field :resource_id, :binary_id, primary_key: true

    field :page_title, :string
    field :page_description, :string
    field :page_site_name, :string
    field :page_url, :string
    field :page_icon_url, :string
    field :page_image_url, :string

    field :state, Ecto.Enum, values: [:loading, :failed, :done]
  end

  def changeset(link_preview, attrs) do
    link_preview
    |> cast(attrs, [:link, :resource_id])
    |> validate_required([:link, :resource_id])
    |> put_change(:state, :loading)
    |> unique_constraint(:link, name: :link_previews_pkey)
  end

  def loaded_changeset(link_preview, attrs) do
    link_preview
    |> cast(attrs, [
      :page_title,
      :page_description,
      :page_site_name,
      :page_url,
      :page_icon_url,
      :page_image_url
    ])
    |> update_change(:page_description, &limit_string(&1, 255, ellipsis: true))
    # Link previews that fail changeset validation will automatically be removed
    # |> validate_required([:page_title, :page_description, :page_image_url])
    |> put_change(:state, :done)
  end

  def failed_changeset(link_preview, _attrs) do
    change(link_preview, state: :failed)
  end

  defp limit_string(str, limit, opts) do
    if opts[:ellipsis] == true and String.length(str) > limit do
      String.slice(str, 0..(limit - 4)) <> "..."
    else
      String.slice(str, 0..(limit - 1))
    end
  end
end
