defmodule GameMasterCore.Repo.Migrations.AddSearchIndexes do
  use Ecto.Migration

  def change do
    # Create text_pattern_ops indexes for efficient ILIKE queries on all entity tables
    # These indexes support case-insensitive pattern matching for search functionality

    # Characters - name search
    execute(
      """
      CREATE INDEX characters_game_id_name_text_pattern_ops_index
      ON characters (game_id, name text_pattern_ops)
      """,
      "DROP INDEX characters_game_id_name_text_pattern_ops_index"
    )

    # Characters - content search
    execute(
      """
      CREATE INDEX characters_game_id_content_text_pattern_ops_index
      ON characters (game_id, content_plain_text text_pattern_ops)
      """,
      "DROP INDEX characters_game_id_content_text_pattern_ops_index"
    )

    # Factions - name search
    execute(
      """
      CREATE INDEX factions_game_id_name_text_pattern_ops_index
      ON factions (game_id, name text_pattern_ops)
      """,
      "DROP INDEX factions_game_id_name_text_pattern_ops_index"
    )

    # Factions - content search
    execute(
      """
      CREATE INDEX factions_game_id_content_text_pattern_ops_index
      ON factions (game_id, content_plain_text text_pattern_ops)
      """,
      "DROP INDEX factions_game_id_content_text_pattern_ops_index"
    )

    # Locations - name search
    execute(
      """
      CREATE INDEX locations_game_id_name_text_pattern_ops_index
      ON locations (game_id, name text_pattern_ops)
      """,
      "DROP INDEX locations_game_id_name_text_pattern_ops_index"
    )

    # Locations - content search
    execute(
      """
      CREATE INDEX locations_game_id_content_text_pattern_ops_index
      ON locations (game_id, content_plain_text text_pattern_ops)
      """,
      "DROP INDEX locations_game_id_content_text_pattern_ops_index"
    )

    # Quests - name search
    execute(
      """
      CREATE INDEX quests_game_id_name_text_pattern_ops_index
      ON quests (game_id, name text_pattern_ops)
      """,
      "DROP INDEX quests_game_id_name_text_pattern_ops_index"
    )

    # Quests - content search
    execute(
      """
      CREATE INDEX quests_game_id_content_text_pattern_ops_index
      ON quests (game_id, content_plain_text text_pattern_ops)
      """,
      "DROP INDEX quests_game_id_content_text_pattern_ops_index"
    )

    # Notes - name search
    execute(
      """
      CREATE INDEX notes_game_id_name_text_pattern_ops_index
      ON notes (game_id, name text_pattern_ops)
      """,
      "DROP INDEX notes_game_id_name_text_pattern_ops_index"
    )

    # Notes - content search
    execute(
      """
      CREATE INDEX notes_game_id_content_text_pattern_ops_index
      ON notes (game_id, content_plain_text text_pattern_ops)
      """,
      "DROP INDEX notes_game_id_content_text_pattern_ops_index"
    )
  end
end
