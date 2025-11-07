defmodule GameMasterCore.Repo.Migrations.ConfirmExistingUsers do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Count users that will be auto-confirmed
    unconfirmed_count =
      repo().one(
        from u in "users",
          where: is_nil(u.confirmed_at),
          select: count(u.id)
      )

    IO.puts("Auto-confirming #{unconfirmed_count} existing unconfirmed users...")

    # Set confirmed_at to inserted_at for all unconfirmed users
    # This treats existing users as if they were confirmed when they signed up
    execute """
    UPDATE users
    SET confirmed_at = inserted_at
    WHERE confirmed_at IS NULL
    """

    IO.puts("✓ Successfully auto-confirmed #{unconfirmed_count} existing users")
  end

  def down do
    # This migration is not reversible - we don't want to un-confirm users
    # If you need to revert, you would need to manually handle the data
    IO.puts("WARNING: This migration cannot be automatically reversed")
    :ok
  end
end
