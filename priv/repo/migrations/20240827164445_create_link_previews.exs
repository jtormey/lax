defmodule Lax.Repo.Migrations.CreateLinkPreviews do
  use Ecto.Migration

  def change() do
    create table(:link_previews, primary_key: false) do
      add :link, :string, null: false, primary_key: true
      add :resource_id, :binary_id, null: false, primary_key: true

      add :page_title, :string
      add :page_description, :string
      add :page_site_name, :string
      add :page_url, :string
      add :page_icon_url, :string
      add :page_image_url, :string

      add :state, :string, null: false
    end

    create index(:link_previews, [:link])
    create index(:link_previews, [:resource_id])
  end
end
