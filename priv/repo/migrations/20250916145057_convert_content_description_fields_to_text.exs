defmodule GameMasterCore.Repo.Migrations.ConvertContentDescriptionFieldsToText do
  use Ecto.Migration

  def change do
    # Convert content fields from varchar(255) to text
    alter table(:games) do
      modify :content, :text
    end

    alter table(:characters) do
      modify :content, :text
    end

    alter table(:factions) do
      modify :content, :text
    end

    alter table(:locations) do
      modify :content, :text
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
