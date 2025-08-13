defmodule WormsInSpaceWeb.Resolvers.SpaceWalkTest do
  use WormsInSpaceWeb.ConnCase

  @query """
  mutation ScheduleWalk($id: ID, $alternateTime: String) {
    wormSpaceWalk(id: $id, alternateTime: $alternateTime) {
      id
      startTime
      status
    }
  }
  """

  test "schedules walk with predefined slot" do
    conn = build_conn()

    conn = post(conn, "/api", %{
      "query" => @query,
      "variables" => %{"id" => "1"}
    })

    assert %{
      "data" => %{
        "wormSpaceWalk" => %{
          "status" => "scheduled"
        }
      }
    } = json_response(conn, 200)
  end

  test "rejects invalid alternate time" do
    conn = build_conn()

    conn = post(conn, "/api", %{
      "query" => @query,
      "variables" => %{"alternateTime" => "not-a-date"}
    })

    assert %{
      "errors" => [%{"message" => _}]
    } = json_response(conn, 200)
  end
end
