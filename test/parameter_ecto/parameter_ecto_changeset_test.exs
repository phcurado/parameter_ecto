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

    def changeset(params) do
      __MODULE__
      |> cast_params(params)
      |> validate_required([:city, :street])
    end
  end

  defmodule ReadmeUserParamTest do
    use Parameter.Schema
    import Parameter.Ecto.Changeset
    import Ecto.Changeset

    enum Status do
      value 1, as: :online
      value 2, as: :offline
    end

    param do
      field :first_name, :string, key: "firstName"
      field :last_name, :string, key: "lastName"
      field :email, :string
      field :status, __MODULE__.Status

      has_one :address, ReadmeAddressParamTest
      has_many :addresses, ReadmeAddressParamTest
    end

    def changeset(params) do
      __MODULE__
      |> cast_params(params)
      |> validate_required([:first_name, :last_name])
      |> validate_format(:email, ~r/@/)
      |> cast_assoc_params(:address, with: &ReadmeAddressParamTest.changeset(&1))
      |> cast_assoc_params(:addresses, with: &ReadmeAddressParamTest.changeset(&1))
    end
  end

  test "test simple example" do
    params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john.doe@email.com",
      "status" => 1
    }

    {param_changeset, _ecto_changeset} = assert_parameter_changeset(params, assoc: false)

    assert {:ok,
            %ReadmeUserParamTest{
              first_name: "John",
              last_name: "Doe",
              email: "john.doe@email.com",
              status: :online,
              address: nil,
              addresses: nil
            }} == Ecto.Changeset.apply_action(param_changeset, :update)
  end

  test "test simple example with errors" do
    params = %{
      "firstName" => "John",
      "email" => "john.doe.email.com",
      "status" => 1
    }

    {param_changeset, _ecto_changeset} = assert_parameter_changeset(params, assoc: false)

    assert {
             :error,
             %Ecto.Changeset{
               action: :update,
               changes: %{email: "john.doe.email.com", first_name: "John", status: :online},
               data: %ReadmeUserParamTest{},
               errors: [
                 email: {"has invalid format", [validation: :format]},
                 last_name: {"can't be blank", [validation: :required]}
               ],
               filters: %{},
               params: %{
                 "email" => "john.doe.email.com",
                 "first_name" => "John",
                 "status" => :online
               },
               required: [:first_name, :last_name],
               types: %{
                 address:
                   {:embed,
                    %Ecto.Embedded{
                      cardinality: :one,
                      field: :address,
                      owner: ReadmeUserParamTest,
                      related: ReadmeAddressParamTest,
                      on_replace: :raise,
                      unique: true,
                      ordered: true
                    }},
                 addresses:
                   {:embed,
                    %Ecto.Embedded{
                      cardinality: :many,
                      field: :addresses,
                      owner: ReadmeUserParamTest,
                      related: ReadmeAddressParamTest,
                      on_replace: :raise,
                      unique: true,
                      ordered: true
                    }},
                 email: :string,
                 first_name: :string,
                 last_name: :string,
                 status: :any
               },
               valid?: false,
               validations: [email: {:format, ~r/@/}]
             }
           } == Ecto.Changeset.apply_action(param_changeset, :update)
  end

  test "test association example" do
    params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john.doe@email.com",
      "status" => 2,
      "address" => %{
        "city" => "New York",
        "street" => "Broadway"
      },
      "addresses" => [
        %{
          "city" => "New York",
          "street" => "Broadway"
        },
        %{
          "city" => "Rio de Janeiro",
          "street" => "Avenida Brasil"
        }
      ]
    }

    {param_changeset, _ecto_changeset} = assert_parameter_changeset(params, assoc: true)

    assert {:ok,
            %ReadmeUserParamTest{
              first_name: "John",
              last_name: "Doe",
              email: "john.doe@email.com",
              status: :offline,
              address: %ReadmeAddressParamTest{city: "New York", street: "Broadway"},
              addresses: [
                %ReadmeAddressParamTest{city: "New York", street: "Broadway"},
                %ReadmeAddressParamTest{city: "Rio de Janeiro", street: "Avenida Brasil"}
              ]
            }} == Ecto.Changeset.apply_action(param_changeset, :update)
  end

  test "test association example with errors" do
    params = %{
      "firstName" => "John",
      "email" => "john.doe.email.com",
      "status" => 1,
      "address" => %{
        "city" => "New York"
      },
      "addresses" => [
        %{
          "city" => "New York",
          "street" => "Broadway"
        },
        %{
          "street" => "Avenida Brasil"
        }
      ]
    }

    {param_changeset, _ecto_changeset} = assert_parameter_changeset(params, assoc: true)

    assert {
             :error,
             %Ecto.Changeset{
               action: :update,
               changes: %{
                 address: %Ecto.Changeset{
                   action: :insert,
                   changes: %{city: "New York"},
                   constraints: [],
                   data: %ReadmeAddressParamTest{},
                   empty_values: [""],
                   errors: [street: {"can't be blank", [validation: :required]}],
                   filters: %{},
                   params: %{"city" => "New York"},
                   prepare: [],
                   repo: nil,
                   repo_opts: [],
                   required: [:city, :street],
                   types: %{city: :string, street: :string},
                   valid?: false,
                   validations: []
                 },
                 addresses: [
                   %Ecto.Changeset{
                     action: :insert,
                     changes: %{city: "New York", street: "Broadway"},
                     constraints: [],
                     data: %ReadmeAddressParamTest{},
                     empty_values: [""],
                     errors: [],
                     filters: %{},
                     params: %{"city" => "New York", "street" => "Broadway"},
                     prepare: [],
                     repo_opts: [],
                     required: [:city, :street],
                     types: %{city: :string, street: :string},
                     valid?: true,
                     validations: []
                   },
                   %Ecto.Changeset{
                     action: :insert,
                     changes: %{street: "Avenida Brasil"},
                     constraints: [],
                     data: %ReadmeAddressParamTest{},
                     empty_values: [""],
                     errors: [city: {"can't be blank", [validation: :required]}],
                     filters: %{},
                     params: %{"street" => "Avenida Brasil"},
                     prepare: [],
                     repo_opts: [],
                     required: [:city, :street],
                     types: %{city: :string, street: :string},
                     valid?: false,
                     validations: []
                   }
                 ],
                 email: "john.doe.email.com",
                 first_name: "John",
                 status: :online
               },
               constraints: [],
               data: %ReadmeUserParamTest{},
               empty_values: [""],
               errors: [
                 email: {"has invalid format", [validation: :format]},
                 last_name: {"can't be blank", [validation: :required]}
               ],
               filters: %{},
               params: %{
                 "email" => "john.doe.email.com",
                 "first_name" => "John",
                 "status" => :online,
                 "address" => %{city: "New York"},
                 "addresses" => [
                   %{city: "New York", street: "Broadway"},
                   %{street: "Avenida Brasil"}
                 ]
               },
               prepare: [],
               repo_opts: [{:force, true}],
               required: [:first_name, :last_name],
               types: %{
                 address: {
                   :embed,
                   %Ecto.Embedded{
                     cardinality: :one,
                     field: :address,
                     on_replace: :raise,
                     ordered: true,
                     owner: ReadmeUserParamTest,
                     related: ReadmeAddressParamTest,
                     unique: true
                   }
                 },
                 addresses: {
                   :embed,
                   %Ecto.Embedded{
                     cardinality: :many,
                     field: :addresses,
                     on_replace: :raise,
                     ordered: true,
                     owner: ReadmeUserParamTest,
                     related: ReadmeAddressParamTest,
                     unique: true
                   }
                 },
                 email: :string,
                 first_name: :string,
                 last_name: :string,
                 status: :any
               },
               valid?: false,
               validations: [email: {:format, ~r/@/}]
             }
           } == Ecto.Changeset.apply_action(param_changeset, :update)
  end

  def assert_parameter_changeset(params, assoc: assoc) do
    assert {:ok, params} = Parameter.load(ReadmeUserParamTest, params)

    raw_param_changeset = ReadmeUserParamTest.changeset(params)
    raw_ecto_changeset = EctoSchemas.ReadmeUserParamTest.changeset(params)

    {param_changeset, ecto_changeset} =
      remove_data_and_types(raw_param_changeset, raw_ecto_changeset)

    {param_changeset, ecto_changeset} =
      if assoc == true do
        remove_nested_data_and_types(param_changeset, ecto_changeset)
      else
        {param_changeset, ecto_changeset}
      end

    assert param_changeset == ecto_changeset
    {raw_param_changeset, raw_ecto_changeset}
  end

  defp remove_data_and_types(param_changeset, ecto_changeset) do
    param_changeset = put_in(param_changeset.data, nil)
    ecto_changeset = put_in(ecto_changeset.data, nil)
    param_changeset = put_in(param_changeset.types, nil)
    ecto_changeset = put_in(ecto_changeset.types, nil)

    {param_changeset, ecto_changeset}
  end

  defp remove_nested_data_and_types(param_changeset, ecto_changeset) do
    param_changeset = put_in(param_changeset.changes.address.data, nil)
    ecto_changeset = put_in(ecto_changeset.changes.address.data, nil)

    param_nested_changeset =
      Enum.map(param_changeset.changes.addresses, fn value ->
        %{value | data: nil}
      end)

    param_changeset = put_in(param_changeset.changes.addresses, param_nested_changeset)

    ecto_nested_changeset =
      Enum.map(ecto_changeset.changes.addresses, fn value ->
        %{value | data: nil}
      end)

    ecto_changeset = put_in(ecto_changeset.changes.addresses, ecto_nested_changeset)

    {param_changeset, ecto_changeset}
  end
end
