defmodule Parameter.Ecto.Changeset do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
  alias Parameter.Field

  @spec cast_params(module(), map()) :: Ecto.Changeset.t()
  def cast_params(schema, params) when is_map(params) do
    types = cast_types_from_schema(schema)
    Ecto.Changeset.cast({schema.__struct__, types}, params, Map.keys(types))
  end

  def cast_assoc_params(changeset, key, with: changeset_func) do
    field_name = to_string(key)

    param_value = changeset.params[field_name]

    field = changeset.data.__struct__.__param__(:field, name: key)
    embed = mount_embed_type(changeset, field)
    types = Map.put(changeset.types, key, embed)
    changeset = %{changeset | types: types}

    run_cast_assoc_params(changeset, field, param_value, changeset_func)
  end

  defp cast_types_from_schema(schema) do
    Enum.map(schema.__param__(:fields), &flatten_params/1)
    |> Enum.reject(&(&1 == nil))
    |> Enum.into(%{})
  end

  defp flatten_params(%Field{type: {:has_one, _inner_module}}) do
    nil
  end

  defp flatten_params(%Field{type: {:has_many, _inner_module}}) do
    nil
  end

  defp flatten_params(%Field{name: name, type: type}) do
    if Ecto.Type.base?(type) do
      {name, type}
    else
      {name, :any}
    end
  end

  defp run_cast_assoc_params(changeset, _field, nil, _changeset_func) do
    changeset
  end

  defp run_cast_assoc_params(
         changeset,
         %Field{name: field_name, type: {:has_many, _inner_module}},
         param_values,
         changeset_func
       )
       when is_list(param_values) do
    Enum.reduce(param_values, changeset, fn param_value, changeset ->
      nested_changeset = changeset_func.(param_value)

      nested_changeset = %{nested_changeset | action: :insert}

      changeset =
        if changeset.valid? and nested_changeset.valid? do
          changeset
        else
          %{changeset | valid?: false}
        end

      nested_changes = Map.get(changeset.changes, field_name, [])

      nested_changes = nested_changes ++ [nested_changeset]

      changes = Map.put(changeset.changes, field_name, nested_changes)
      %{changeset | repo_opts: [{:force, true}], changes: changes}
    end)
  end

  defp run_cast_assoc_params(changeset, %Field{name: field_name}, param_value, changeset_func) do
    nested_changeset = changeset_func.(param_value)

    nested_changeset = %{nested_changeset | action: :insert}

    changeset =
      if changeset.valid? and nested_changeset.valid? do
        changeset
      else
        %{changeset | valid?: false}
      end

    changes = Map.put(changeset.changes, field_name, nested_changeset)

    %{changeset | repo_opts: [{:force, true}], changes: changes}
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

  defp mount_embed_type(changeset, %Field{name: name, type: {:has_many, inner_module}}) do
    {:embed,
     %Ecto.Embedded{
       cardinality: :many,
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
