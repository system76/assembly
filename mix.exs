defmodule Assembly.MixProject do
  use Mix.Project

  def project do
    [
      app: :assembly,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        assembly: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Assembly.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal, "~> 1.0"},
      {:bottle, github: "system76/bottle", branch: "elixir", sha: "008b650"},
      {:broadway_sqs, "~> 0.6.0"},
      {:cachex, "~> 3.3"},
      {:cowlib, "~> 2.9.0", override: true},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.5"},
      {:elixir_uuid, "~> 1.2"},
      {:hackney, "~> 1.16"},
      {:jason, "~> 1.2", override: true},
      {:mox, "~> 1.0"},
      {:postgrex, "~> 0.15.7"},
      {:saxy, "~> 1.1"},
      {:credo, "~> 1.3", only: [:dev, :test]}
    ]
  end
end