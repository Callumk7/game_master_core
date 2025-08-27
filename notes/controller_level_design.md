# Controller Level Design

```elixir
  @doc """
  Returns all characters linked to a note.
  """
  def linked_characters(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end
```

Return an empty array when the note is not found. This is a design choice. This means that we can handle not found as a 404 on the router level.
Also makes it easier for the client to iterate over the list when dealing with the response.

