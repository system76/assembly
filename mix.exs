defmodule Assembly.MixProject do
  use Mix.Project

  def project do
    [
      app: :assembly,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
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
      {:bottle, github: "system76/bottle", branch: "elixir"},
      {:broadway_sqs, "~> 0.6.0"},
      {:credo, "~> 1.3", only: [:dev, :test]},
      {:ecto_sql, "~> 3.5"},
      {:hackney, "~> 1.16"},
      {:jason, "~> 1.2", override: true},
      {:myxql, "~> 0.4"},
      {:phoenix_pubsub, "~> 2.0"},
      {:postgrex, "~> 0.15"},
      {:saxy, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
