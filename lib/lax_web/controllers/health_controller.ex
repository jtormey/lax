defmodule LaxWeb.HealthController do
  use LaxWeb, :controller

  def health(conn, _params) do
    json(conn, %{status: :ok})
  end
end
