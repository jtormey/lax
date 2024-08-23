defmodule LaxWeb.PageController do
  use LaxWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

  def support(conn, _params) do
    render(conn, :support)
  end
end
