defmodule GameMasterCore.Repo.Migrations.AddIsPublicToGamesAndEntities do
  use Ecto.Migration

  def up do
    alter table(:games) do
      add :is_public, :boolean, null: false, default: false
    end

    alter table(:characters) do
      add :is_public, :boolean, null: false, default: false
    end

    alter table(:factions) do
      add :is_public, :boolean, null: false, default: false
    end

    alter table(:locations) do
      add :is_public, :boolean, null: false, default: false
    end

    alter table(:notes) do
      add :is_public, :boolean, null: false, default: false
    end

    alter table(:quests) do
      add :is_public, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:games) do
      remove :is_public
    end

    alter table(:characters) do
      remove :is_public
    end

    alter table(:factions) do
      remove :is_public
    end

    alter table(:locations) do
      remove :is_public
    end

    alter table(:notes) do
      remove :is_public
    end

    alter table(:quests) do
      remove :is_public
    end
  end
end
