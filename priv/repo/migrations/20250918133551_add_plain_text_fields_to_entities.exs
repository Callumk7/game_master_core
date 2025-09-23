defmodule GameMasterCore.Repo.Migrations.AddPlainTextFieldsToEntities do
  use Ecto.Migration

  def change do
    # Add content_plain_text to entities with content fields
    alter table(:characters) do
      add :content_plain_text, :text
    end

    alter table(:factions) do
      add :content_plain_text, :text
    end

    alter table(:locations) do
      add :content_plain_text, :text
    end

    alter table(:games) do
      add :content_plain_text, :text
    end

    # Add content_plain_text to entities with content fields
    alter table(:quests) do
      add :content_plain_text, :text
    end

    alter table(:notes) do
      add :content_plain_text, :text
    end
  end
end
