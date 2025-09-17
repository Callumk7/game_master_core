defmodule GameMasterCore.Repo.Migrations.ConvertContentDescriptionFieldsToText do
  use Ecto.Migration

  def change do
    # Convert description fields from varchar(255) to text
    alter table(:games) do
      modify :description, :text
    end

    alter table(:characters) do
      modify :description, :text
    end

    alter table(:factions) do
      modify :description, :text
    end

    alter table(:locations) do
      modify :description, :text
    end

    # Convert content fields from varchar(255) to text
    alter table(:notes) do
      modify :content, :text
    end

    alter table(:quests) do
      modify :content, :text
    end
  end
end
