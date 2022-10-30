defmodule Parameter.Ecto.Changeset do
  alias Parameter.Field
  alias Parameter.Types

  def cast_params(schema, params, opts \\ []) do
    types = cast_types_from_schema(schema, params)

    schema =
      if opts[:struct] do
        schema.__struct__
      else
        %{}
      end

    {schema, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end

  def cast_assoc_params(changeset, key, with: changeset_func) do
    field_name = to_string(key)

    nested_changeset = changeset_func.(changeset.params[field_name])

    nested_changeset = %{nested_changeset | action: :insert}

    changeset =
      if nested_changeset.valid? do
        changeset
      else
        %{changeset | valid?: false}
      end

    changes = Map.put(changeset.changes, key, nested_changeset)
    field = changeset.data.__struct__.__param__(:field, name: key)

    embed = mount_embed_type(changeset, field)

    types = Map.put(changeset.types, key, embed)
    %{changeset | repo_opts: [{:force, true}], changes: changes, types: types}
  end

  def apply_params(changeset, _opts \\ []) do
    Ecto.Changeset.apply_action(changeset, :update)
  end

  defp cast_types_from_schema(schema, params) do
    Enum.map(schema.__param__(:fields), &flatten_params(&1, params))
    |> Enum.reject(&(&1 == nil))
    |> Enum.into(%{})
  end

  defp flatten_params(%Field{name: name, type: {:has_one, inner_module}}, _params) do
    # {name, :map}
    nil
  end

  defp flatten_params(%Field{name: name, type: type}, _params) do
    if type in Types.base_types() do
      {name, type}
    else
      nil
    end
  end

  defp mount_embed_type(changeset, %Field{name: name, type: {:has_one, inner_module}}) do
    {:embed,
     %Ecto.Embedded{
       cardinality: :one,
       field: name,
       owner: changeset.data.__struct__,
       related: inner_module,
       on_cast: nil,
       on_replace: :raise,
       unique: true,
       ordered: true
     }}
  end
end
