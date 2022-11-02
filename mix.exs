defmodule Parameter.Ecto.MixProject do
  use Mix.Project

  @source_url "https://github.com/phcurado/parameter_ecto"
  @version "0.1.1"

  def project do
    [
      app: :parameter_ecto,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Hex
      description: "Integrates Parameter with Ecto",
      source_url: @source_url,
      package: package(),
      # Docs
      name: "Parameter",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:parameter, "~> 0.6"},
      {:ecto, "~> 3.3"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package() do
    [
      maintainers: ["Paulo Curado"],
      licenses: ["Apache-2.0"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Parameter.Ecto.Changeset",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/parameter_ecto",
      source_url: @source_url
    ]
  end
end
