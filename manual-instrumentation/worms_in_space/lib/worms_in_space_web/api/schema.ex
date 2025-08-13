defmodule WormsInSpaceWeb.Api.Schema do
  use Absinthe.Schema


  query do
    field :worm_time_slots, non_null(list_of(:time_slot))  do
      resolve &Api.Resolvers.list/2
    end
    
    field :scheduled_walks, non_null(list_of(:scheduled_walk)) do
      resolve &Api.Resolvers.list_scheduled_walks/2
    end
  end

  mutation do
    field :worm_space_walk, :scheduled_walk do
      arg :id, :id
      arg :alternate_time, :string

      resolve &Api.Resolvers.create/2
    end
    
    field :delete_scheduled_walk, :scheduled_walk do
      arg :id, non_null(:id)
      
      resolve &Api.Resolvers.delete_scheduled_walk/2
    end
  end

  object :time_slot do
    field :id, non_null(:id)
    field :start_time, non_null(:string)
  end
  
  object :scheduled_walk do
    field :id, non_null(:id)
    field :start_time, non_null(:string)
    field :walk_type, non_null(:string)
    field :slot_id, :string
    field :status, non_null(:string)
    field :scheduled_at, non_null(:string)
  end
end
