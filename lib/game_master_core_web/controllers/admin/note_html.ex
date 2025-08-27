defmodule GameMasterCoreWeb.Admin.NoteHTML do
  use GameMasterCoreWeb, :html

  embed_templates "note_html/*"

  @doc """
  Renders a note form.

  The form is defined in the template at
  note_html/note_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def note_form(assigns)
end
