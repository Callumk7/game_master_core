defmodule GameMasterCoreWeb.Admin.CharacterHTML do
  use GameMasterCoreWeb, :html

  embed_templates "character_html/*"

  @doc """
  Renders a character form.

  The form is defined in the template at
  character_html/character_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def character_form(assigns)
end
