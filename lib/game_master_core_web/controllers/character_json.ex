defmodule GameMasterCoreWeb.CharacterJSON do
  alias GameMasterCore.Characters.Character

  @doc """
  Renders a list of characters.
  """
  def index(%{characters: characters}) do
    %{data: for(character <- characters, do: data(character))}
  end

  @doc """
  Renders a single character.
  """
  def show(%{character: character}) do
    %{data: data(character)}
  end

  defp data(%Character{} = character) do
    %{
      id: character.id,
      name: character.name,
      description: character.description,
      class: character.class,
      level: character.level,
      image_url: character.image_url
    }
  end
end
