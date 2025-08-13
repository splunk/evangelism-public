defmodule WormsInSpaceWeb.ErrorHandler do
  require Logger

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    Logger.error("Request failed: #{inspect(reason)}")

    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.json(%{error: "Internal server error"})
  end
end
