defmodule GameMasterCore.Repo.Migrations.RemoveDeprecatedColumns do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      remove :member_of_faction_id
      remove :faction_role
    end
  end
end
