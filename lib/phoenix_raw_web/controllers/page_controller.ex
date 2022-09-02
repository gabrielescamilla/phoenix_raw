defmodule PhoenixRawWeb.PageController do
  use PhoenixRawWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
