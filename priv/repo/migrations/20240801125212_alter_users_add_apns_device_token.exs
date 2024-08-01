defmodule Lax.Repo.Migrations.AlterUsersAddDeviceToken do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :apns_device_token, {:array, :string}, default: [], null: false
    end
  end
end
