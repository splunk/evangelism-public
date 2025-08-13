defmodule WormsInSpace.Test.Support.GraphqlHelper do
  import Phoenix.ConnTest

  @endpoint WormsInSpaceWeb.Endpoint

  def query(conn, options) do
    conn
    |> post(
      "/api",
      build_query(options[:query], options[:variables])
    )
    |> json_response(200)
  end

  defp build_query(query, variables) do
    %{
      "query" => query,
      "variables" => variables
    }
  end
end
