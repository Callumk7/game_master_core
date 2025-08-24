defmodule GameMasterCoreWeb.Admin.GameHTML do
  use GameMasterCoreWeb, :html

  embed_templates "game_html/*"

  @doc """
  Renders a game form.

  The form is defined in the template at
  game_html/game_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def game_form(assigns)
end
