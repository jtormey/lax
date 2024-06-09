defmodule Lax.Repo.Migrations.AlterChannelsUsersModifyLastViewedAt do
  use Ecto.Migration

  def change do
    alter table(:channels_users) do
      modify :last_viewed_at, :naive_datetime_usec, null: true, from: {:utc_datetime, null: true}
    end
  end
end
