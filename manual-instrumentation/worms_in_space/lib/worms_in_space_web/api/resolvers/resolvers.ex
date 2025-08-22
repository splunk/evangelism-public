defmodule Api.Resolvers do
  alias WormsInSpace.{Repo, ScheduledWalk}
  import Ecto.Query
  require OpenTelemetry.Tracer, as: Tracer

  @time_slots [
    %{id: 2, start_time: "2020-02-28T16:00:00.000Z"},
    %{id: 6, start_time: "2020-02-28T21:00:00.000Z"},
    %{id: 9, start_time: "2020-02-28T14:00:00.000Z"}
  ]
  
  def list(_args, _info) do
    {:ok, @time_slots}
  end

  def list_scheduled_walks(_args, _info) do
    Tracer.with_span "resolver.list_scheduled_walks" do
      walks = 
        ScheduledWalk
        |> where([w], w.status == "scheduled")
        |> order_by([w], desc: w.inserted_at)
        |> Repo.all()
        |> Enum.map(fn walk ->
          %{
            id: walk.id,
            start_time: DateTime.to_iso8601(walk.start_time),
            walk_type: walk.walk_type,
            slot_id: walk.slot_id,
            status: walk.status,
            scheduled_at: NaiveDateTime.to_iso8601(walk.inserted_at) <> "Z"
          }
        end)
      
      Tracer.set_attributes([
        {"spacewalks.count", length(walks)}
      ])
      
      {:ok, walks}
    end
  end

  def create(%{alternate_time: _alternate_time, id: _id}, _info) do
    {:error, %{message: "Bad input.", status: 404}}
  end

  def create(%{alternate_time: alternate_time}, _info) do
    Tracer.with_span "resolver.schedule_spacewalk" do
      Tracer.set_attributes([
        {"spacewalk.type", "custom"},
        {"spacewalk.time", alternate_time}
      ])
      
      case DateTime.from_iso8601(alternate_time) do
        {:ok, datetime, _} ->
          changeset = ScheduledWalk.changeset(%ScheduledWalk{}, %{
            start_time: datetime,
            walk_type: "custom"
          })
          
          case Repo.insert(changeset) do
            {:ok, walk} ->
              Tracer.set_attributes([
                {"spacewalk.id", walk.id},
                {"spacewalk.scheduled", true}
              ])
              Tracer.set_status(:ok)
              
              {:ok, %{
                id: walk.id,
                start_time: DateTime.to_iso8601(walk.start_time),
                walk_type: walk.walk_type,
                slot_id: walk.slot_id,
                status: walk.status,
                scheduled_at: NaiveDateTime.to_iso8601(walk.inserted_at) <> "Z"
              }}
            {:error, _changeset} ->
              Tracer.set_status(:error, "Failed to schedule spacewalk")
              {:error, %{message: "Failed to schedule spacewalk", status: 400}}
          end
        {:error, _} ->
          Tracer.set_status(:error, "Invalid datetime format")
          {:error, %{message: "Invalid datetime format", status: 400}}
      end
    end
  end

  def create(%{id: id}, _info) do
    Tracer.with_span "resolver.schedule_spacewalk" do
      Tracer.set_attributes([
        {"spacewalk.type", "predefined"},
        {"timeslot.id", id}
      ])
      
      slot = Enum.find(@time_slots, fn %{id: existing_id} ->
        existing_id == String.to_integer(id)
      end)
      
      case slot do
        nil -> 
          Tracer.set_status(:error, "Time slot not found")
          {:error, %{message: "Time slot not found", status: 400}}
        slot ->
          case DateTime.from_iso8601(slot.start_time) do
            {:ok, datetime, _} ->
              changeset = ScheduledWalk.changeset(%ScheduledWalk{}, %{
                start_time: datetime,
                walk_type: "predefined",
                slot_id: id
              })
              
              case Repo.insert(changeset) do
                {:ok, walk} ->
                  Tracer.set_attributes([
                    {"spacewalk.id", walk.id},
                    {"spacewalk.scheduled", true}
                  ])
                  Tracer.set_status(:ok)
                  
                  {:ok, %{
                    id: walk.id,
                    start_time: DateTime.to_iso8601(walk.start_time),
                    walk_type: walk.walk_type,
                    slot_id: walk.slot_id,
                    status: walk.status,
                    scheduled_at: NaiveDateTime.to_iso8601(walk.inserted_at) <> "Z"
                  }}
                {:error, _changeset} ->
                  Tracer.set_status(:error, "Failed to schedule spacewalk")
                  {:error, %{message: "Failed to schedule spacewalk", status: 400}}
              end
            {:error, _} ->
              Tracer.set_status(:error, "Invalid slot datetime")
              {:error, %{message: "Invalid slot datetime", status: 400}}
          end
      end
    end
  end
  
  def delete_scheduled_walk(%{id: id}, _info) do
    Tracer.with_span "resolver.delete_spacewalk" do
      Tracer.set_attributes([
        {"spacewalk.id", id}
      ])
      
      case Repo.get(ScheduledWalk, id) do
        nil ->
          Tracer.set_status(:error, "Scheduled walk not found")
          {:error, %{message: "Scheduled walk not found", status: 404}}
        walk ->
          case Repo.update(ScheduledWalk.changeset(walk, %{status: "cancelled"})) do
            {:ok, updated_walk} ->
              Tracer.set_attributes([
                {"spacewalk.cancelled", true},
                {"spacewalk.walk_type", updated_walk.walk_type}
              ])
              Tracer.set_status(:ok)
              
              {:ok, %{
                id: updated_walk.id,
                start_time: DateTime.to_iso8601(updated_walk.start_time),
                walk_type: updated_walk.walk_type,
                slot_id: updated_walk.slot_id,
                status: updated_walk.status,
                scheduled_at: NaiveDateTime.to_iso8601(updated_walk.inserted_at) <> "Z"
              }}
            {:error, _changeset} ->
              Tracer.set_status(:error, "Failed to cancel spacewalk")
              {:error, %{message: "Failed to cancel spacewalk", status: 400}}
          end
      end
    end
  end
end
