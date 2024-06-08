defmodule Lax.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false

      timestamps()
    end

    create table(:default_channels, primary_key: false) do
      add :channel_id, references(:channels, type: :binary_id, on_delete: :delete_all),
        primary_key: true
    end

    create table(:channels_users, primary_key: false) do
      add :channel_id, references(:channels, type: :binary_id), primary_key: true
      add :user_id, references(:users, type: :binary_id), primary_key: true
      add :last_viewed_at, :utc_datetime, null: true

      timestamps(updated_at: false)
    end

    create index(:channels_users, [:channel_id])
    create index(:channels_users, [:user_id])

    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :text, null: false
      add :channel_id, references(:channels, type: :binary_id), null: false
      add :sent_by_user_id, references(:users, type: :binary_id), null: false

      timestamps()
    end

    create index(:messages, [:channel_id])
    create index(:messages, [:sent_by_user_id])
  end
end
