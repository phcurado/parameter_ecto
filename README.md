# Parameter.Ecto
<!-- MDOC !-->
Integrates [Parameter](https://github.com/phcurado/parameter) with [Ecto](https://github.com/elixir-ecto/ecto) for changeset casting and validation.

```elixir
defmodule UserParam do
  use Parameter.Schema
  import Parameter.Ecto.Changeset
  import Ecto.Changeset

  param do
    field :first_name, :string, key: "firstName"
    field :last_name, :string, key: "lastName"
    field :email, :string

    has_one :address, AddressParam
  end

  def changeset(params) do
    __MODULE__
    |> cast_params(params) # Parameter function that automatically identify param fields
    |> validate_required([:first_name, :last_name])
    |> validate_format(:email, ~r/@/)
    |> cast_assoc_params(:address, with: &AddressParam.changeset(&1))
  end
end

defmodule AddressParam do
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

# Casting the changeset
iex> params = %{
  "firstName" => "John",
  "lastName" => "Doe",
  "email" => "john.doe@email.com",
  "address" => %{
    "city" => "New York",
    "street" => "Broadway"
  }
}
...> {:ok, loaded_params} = Parameter.load(UserParam, params)
...> changeset = UserParam.changeset(loaded_params)
%Ecto.Changeset{
  action: nil,
  changes: %{
    address: %Ecto.Changeset{
      action: :insert,
      changes: %{city: "New York", street: "Broadway"},
      errors: [],
      data: %AddressParam{},
      valid?: true
    },
    email: "john.doe@email.com",
    first_name: "John",
    last_name: "Doe"
  },
  errors: [],
  data: %UserParam{},
  valid?: true
}
...> Ecto.Changeset.apply_action(changeset, :update)
{:ok,
 %UserParam{
   first_name: "John",
   last_name: "Doe",
   email: "john.doe@email.com",
   address: %AddressParam{city: "New York", street: "Broadway"}
 }}
```

## Installation

Add `parameter_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "..."},
    {:parameter_ecto, "~> 0.1.0"}
  ]
end
```

Checkout the oficial documentation for more information.

