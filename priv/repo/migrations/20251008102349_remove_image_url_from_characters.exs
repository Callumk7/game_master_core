defmodule GameMasterCore.Repo.Migrations.RemoveImageUrlFromCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      remove :image_url, :string
    end
  end
end
