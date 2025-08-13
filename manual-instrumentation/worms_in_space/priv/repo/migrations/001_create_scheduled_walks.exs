defmodule WormsInSpace.Repo.Migrations.CreateScheduledWalks do
  use Ecto.Migration

  def change do
    create table(:scheduled_walks) do
      add :start_time, :utc_datetime, null: false
      add :walk_type, :string, null: false  # "predefined" or "custom"
      add :slot_id, :string            # ID of the predefined slot if applicable
      add :status, :string, default: "scheduled"  # scheduled, cancelled, completed

      timestamps()
    end

    create index(:scheduled_walks, [:start_time])
    create index(:scheduled_walks, [:status])
  end
end