defmodule WormsInSpaceSchemaTest do
  use WormsInSpaceWeb.ConnCase

  describe "query" do
    test "timeSlots field returns list of timeSlots" do
      %{"data" => %{"wormTimeSlots" => time_slots}} = build_conn()
        |> query(query: """
        {
          wormTimeSlots {
            id
            startTime
          }
        }
        """)

        assert length(time_slots) == 3
        assert Enum.member?(time_slots, %{"id" => "2", "startTime" => "2020-02-28T16:00:00.000Z"})
    end
  end

  describe "mutation" do
    test "return startTime for wormSpaceWalk with alternateTime arg" do
      %{"data" => %{"wormSpaceWalk" => %{"startTime" => start_time}}} = build_conn()
        |> query(query: """
        mutation{
          wormSpaceWalk(alternateTime: "2022-02-28T16:00:00.000Z"){
            startTime
          }
        }
        """)

      assert start_time == "2022-02-28T16:00:00.000Z"
    end

    test "return startTime for wormSpaceWalk with existing ID arg" do
      %{"data" => %{"wormSpaceWalk" => %{"startTime" => start_time}}} = build_conn()
        |> query(query: """
        mutation{
          wormSpaceWalk(id: 2){
            startTime
          }
        }
        """)

      assert start_time == "2020-02-28T16:00:00.000Z"
    end

    test "returns error for wormSpaceWalk with non-existant ID arg" do
      %{"data" => %{"wormSpaceWalk" => worm_space_walk}, "errors" => errors } = build_conn()
        |> query(query: """
        mutation{
          wormSpaceWalk(id: 8){
            startTime
          }
        }
        """)

      assert is_nil(worm_space_walk)
      assert get_in(errors, [Access.at(0), "message"]) == "Not found"
      assert get_in(errors, [Access.at(0), "status"]) == 400
    end

    test "returns error for wormSpaceWalk with both ID and alternateTime arg" do
      %{"data" => %{"wormSpaceWalk" => worm_space_walk}, "errors" => errors } = build_conn()
        |> query(query: """
        mutation{
          wormSpaceWalk(id: 8, alternateTime: "Alternate time!"){
            startTime
          }
        }
        """)

      assert is_nil(worm_space_walk)
      assert get_in(errors, [Access.at(0), "message"]) == "Bad input."
      assert get_in(errors, [Access.at(0), "status"]) == 404
    end
  end

end
