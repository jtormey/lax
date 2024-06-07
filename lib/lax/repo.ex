defmodule Lax.Repo do
  use Ecto.Repo,
    otp_app: :lax,
    adapter: Ecto.Adapters.Postgres
end
