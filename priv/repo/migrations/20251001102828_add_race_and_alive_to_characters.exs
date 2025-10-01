defmodule GameMasterCore.Repo.Migrations.AddRaceAndAliveToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :race, :string
      add :alive, :boolean, default: true
    end
  end
end
