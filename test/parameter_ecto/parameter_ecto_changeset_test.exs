defmodule Parameter.Ecto.ChangesetTest do
  use ExUnit.Case
  doctest Parameter.Ecto.Changeset

  alias Parameter.Support.EctoSchemas

  defmodule ReadmeAddressParamTest do
    use Parameter.Schema
    import Parameter.Ecto.Changeset
    import Ecto.Changeset

    param do
      field :city, :string
      field :street, :string
    end

    def changeset(params, opts \\ []) do
      __MODULE__
      |> cast_params(params, opts)
      |> validate_required([:city, :street])
    end
  end

  defmodule ReadmeUserParamTest do
    use Parameter.Schema
    import Parameter.Ecto.Changeset
    import Ecto.Changeset

    param do
      field :first_name, :string, key: "firstName"
      field :last_name, :string, key: "lastName"
      field :email, :string

      has_one :address, ReadmeAddressParamTest
    end

    def changeset(params, opts \\ []) do
      __MODULE__
      |> cast_params(params, opts)
      |> validate_required([:first_name, :last_name])
      |> validate_format(:email, ~r/@/)
      |> cast_assoc_params(:address, with: &ReadmeAddressParamTest.changeset(&1, opts))
    end
  end

  test "test readme example" do
    params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john.doe@email.com",
      "address" => %{
        "city" => "New York",
        "street" => "Broadway"
      }
    }

    assert {:ok, loaded_params} = Parameter.load(ReadmeUserParamTest, params)

    param_changeset = ReadmeUserParamTest.changeset(loaded_params, struct: true)
    ecto_changeset = EctoSchemas.ReadmeUserParamTest.changeset(loaded_params)

    assert %ReadmeUserParamTest{} == param_changeset.data
    assert %ReadmeAddressParamTest{} == param_changeset.changes.address.data

    param_changeset = Map.put(param_changeset, :data, nil)
    ecto_changeset = Map.put(ecto_changeset, :data, nil)

    param_changeset = put_in(param_changeset.changes.address.data, nil)
    ecto_changeset = put_in(ecto_changeset.changes.address.data, nil)

    param_changeset = put_in(param_changeset.types.address, nil)
    ecto_changeset = put_in(ecto_changeset.types.address, nil)

    assert param_changeset == ecto_changeset
  end
end
