defmodule Parameter.Support.EctoSchemas do
  @moduledoc false
  defmodule ReadmeAddressParamTest do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :city, :string
      field :street, :string
    end

    def changeset(address, params) do
      address
      |> cast(params, [:city, :street])
      |> validate_required([:city, :street])
    end
  end

  defmodule ReadmeUserParamTest do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :email, :string
      field :status, Ecto.Enum, values: [:online, :offline]

      embeds_one(:address, ReadmeAddressParamTest)
      embeds_many(:addresses, ReadmeAddressParamTest)
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:first_name, :last_name, :email, :status])
      |> validate_required([:first_name, :last_name])
      |> validate_format(:email, ~r/@/)
      |> cast_embed(:address)
      |> cast_embed(:addresses)
    end
  end
end
