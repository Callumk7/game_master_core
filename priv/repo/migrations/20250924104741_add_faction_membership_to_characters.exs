defmodule GameMasterCore.Repo.Migrations.AddFactionMembershipToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :member_of_faction_id, references(:factions, type: :binary_id, on_delete: :nilify_all)
      add :faction_role, :string
    end

    create index(:characters, [:member_of_faction_id])
  end
end
