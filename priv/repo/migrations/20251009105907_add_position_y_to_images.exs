defmodule GameMasterCore.Repo.Migrations.AddPositionYToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :position_y, :integer, default: 50, null: false
    end
  end
end
