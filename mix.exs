defmodule Assembly.MixProject do
  use Mix.Project

  def project do
    [
      app: :assembly,
      aliases: aliases(),
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 2.0", override: true},
      {:appsignal, "~> 1.0"},
      {:bottle, github: "system76/bottle", ref: "710132e"},
      {:broadway_rabbitmq, "~> 0.6"},
      {:cachex, "~> 3.3"},
      {:cowlib, "~> 2.9.0", override: true},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.5"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws_sqs, "~> 3.2"},
      {:ex_aws, "~> 2.1.6"},
      {:hackney, "~> 1.16"},
      {:jason, "~> 1.2", override: true},
      {:postgrex, "~> 0.15.7"},
      {:saxy, "~> 1.1"},
      {:credo, "~> 1.4", only: [:dev, :test]},
      {:ex_machina, "~> 2.4", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
