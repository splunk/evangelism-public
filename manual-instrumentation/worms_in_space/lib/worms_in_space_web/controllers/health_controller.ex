defmodule WormsInSpaceWeb.HealthController do
  use WormsInSpaceWeb, :controller

  def check(conn, _params) do
    health_status = %{
      status: "healthy",
      service: "worms-in-space",
      version: "1.0.0",
      timestamp: DateTime.utc_now()
    }

    json(conn, health_status)
  end
end
