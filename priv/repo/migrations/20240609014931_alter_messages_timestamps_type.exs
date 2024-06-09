defmodule Lax.Repo.Migrations.AlterMessagesTimestampsType do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :inserted_at, :naive_datetime_usec, null: false, from: {:naive_datetime, null: false}
      modify :updated_at, :naive_datetime_usec, null: false, from: {:naive_datetime, null: false}
    end
  end
end
