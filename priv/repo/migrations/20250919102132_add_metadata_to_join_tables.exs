defmodule GameMasterCore.Repo.Migrations.AddMetadataToJoinTables do
  use Ecto.Migration

  def change do
    # Cross-entity join tables - add all metadata fields
    cross_entity_tables = [
      :character_factions,
      :character_locations,
      :character_notes,
      :faction_locations,
      :faction_notes,
      :location_notes,
      :quests_characters,
      :quests_factions,
      :quests_locations,
      :quests_notes
    ]

    Enum.each(cross_entity_tables, fn table ->
      alter table(table) do
        add :relationship_type, :string
        add :description, :text
        add :strength, :integer
        add :is_active, :boolean, default: true
        add :metadata, :map
      end
    end)

    # Self-referencing join tables - add remaining metadata fields (already have relationship_type)
    self_referencing_tables = [
      :character_characters,
      :faction_factions,
      :location_locations,
      :quest_quests,
      :note_notes
    ]

    Enum.each(self_referencing_tables, fn table ->
      alter table(table) do
        add :description, :text
        add :strength, :integer
        add :is_active, :boolean, default: true
        add :metadata, :map
      end
    end)
  end
end
