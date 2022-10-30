# Parameter.Ecto

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

    has_one :address, Address do
      field :city, :string, required: true
      field :street, :string, required: true
    end
  end

  def new(params, opts \\ []) do
    __MODULE__
    |> Parameter.load(params, opts)
    |> changeset()
    |> apply_params(opts) # Parameter function that applies the changeset into `{:ok, result}` or `{:error, changeset}`
  end

  def changeset(params) do
    __MODULE__
    |> cast_params(params) # Parameter function that automatically identify your param fields
    |> validate_required([:first_name, :last_name])
    |> validate_format(:email, ~r/@/)
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
...> UserParam.changeset(%UserParam{}, params)
#Ecto.Changeset<action: nil, changes: %{address: %{"city" => "New York", "street" => "Broadway"}, email: "john.doe@email.com"}, errors: [first_name: {"can't be blank", [validation: :required]}, last_name: {"can't be blank", [validation: :required]}], data: #Parameter.EctoChangesetTest.ReadmeTest<>, valid?: false>

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

