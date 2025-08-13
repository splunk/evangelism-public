defmodule WormsInSpaceWeb.Schema.Types do
  use Absinthe.Schema.Notation

  object :worm_time_slot do
    field :id, non_null(:id)
    field :start_time, non_null(:datetime)
    field :end_time, non_null(:datetime)
    field :available, non_null(:boolean)
    field :worm_id, :id
  end

  object :space_walk do
    field :id, non_null(:id)
    field :worm_id, non_null(:id)
    field :scheduled_time, non_null(:datetime)
    field :duration_minutes, :integer
    field :status, non_null(:walk_status)
    field :created_at, non_null(:datetime)
  end

  enum :walk_status do
    value :scheduled
    value :in_progress
    value :completed
    value :cancelled
  end

  input_object :schedule_walk_input do
    field :slot_id, :id
    field :alternate_time, :datetime
    field :duration_minutes, :integer, default_value: 30
  end
end
