defmodule GameMasterCore.Repo.Migrations.AddUsernameAndAvatarToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :avatar_url, :string
    end

    create unique_index(:users, [:username])
  end
end
