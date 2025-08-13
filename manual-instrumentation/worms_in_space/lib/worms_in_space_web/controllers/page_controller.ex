defmodule WormsInSpaceWeb.PageController do
  use WormsInSpaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
