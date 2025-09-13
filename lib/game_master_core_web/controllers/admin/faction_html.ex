defmodule GameMasterCoreWeb.Admin.FactionHTML do
  use GameMasterCoreWeb, :html

  embed_templates "faction_html/*"

  @doc """
  Renders a faction form.

  The form is defined in the template at
  faction_html/faction_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def faction_form(assigns)
end
