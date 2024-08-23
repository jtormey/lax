defmodule Lax.Repo.Migrations.AlterUsersAddDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :deleted_at, :naive_datetime, null: true
    end
  end
end
