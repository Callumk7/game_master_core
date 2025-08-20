defmodule GameMasterCore.Repo do
  use Ecto.Repo,
    otp_app: :game_master_core,
    adapter: Ecto.Adapters.Postgres
end
