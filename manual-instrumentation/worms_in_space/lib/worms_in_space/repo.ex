defmodule WormsInSpace.Repo do
  use Ecto.Repo,
    otp_app: :worms_in_space,
    adapter: Ecto.Adapters.Postgres
end