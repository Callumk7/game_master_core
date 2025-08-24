defmodule GameMasterCore.Factions.Faction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factions" do
    field :name, :string
    field :description, :string
    field :game_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction, attrs, game_scope) do
    faction
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> put_change(:game_id, game_scope.game.id)
  end
end
