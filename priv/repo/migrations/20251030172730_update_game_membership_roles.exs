defmodule GameMasterCore.Repo.Migrations.UpdateGameMembershipRoles do
  use Ecto.Migration

  def up do
    # Current roles: ["member", "owner"]
    # New roles: ["admin", "game_master", "member"]

    # Map any existing "owner" role entries to "admin"
    # (Note: ownership is primarily tracked via game.owner_id, so there may be no "owner" entries)
    execute "UPDATE game_members SET role = 'admin' WHERE role = 'owner'"
  end

  def down do
    # Reverse the migration
    execute "UPDATE game_members SET role = 'owner' WHERE role = 'admin'"
    execute "UPDATE game_members SET role = 'member' WHERE role = 'game_master'"
  end
end
