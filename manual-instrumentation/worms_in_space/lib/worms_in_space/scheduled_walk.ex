defmodule WormsInSpace.ScheduledWalk do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "scheduled_walks" do
    field :start_time, :utc_datetime
    field :walk_type, :string  # "predefined" or "custom"
    field :slot_id, :string
    field :status, :string, default: "scheduled"

    timestamps()
  end

  @doc false
  def changeset(scheduled_walk, attrs) do
    scheduled_walk
    |> cast(attrs, [:start_time, :walk_type, :slot_id, :status])
    |> validate_required([:start_time, :walk_type])
    |> validate_inclusion(:walk_type, ["predefined", "custom"])
    |> validate_inclusion(:status, ["scheduled", "cancelled", "completed"])
  end
end