defmodule Assembly.MixProject do
  use Mix.Project

  def project do
    [
      app: :assembly,
      aliases: aliases(),
      version: "0.1.0",
      elixir: "~> 1.14.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
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
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  # Setup dialyzer plt files in /priv for easier caching.
  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 2.0", override: true},
      {:bottle, github: "system76/bottle", ref: "cd3e55c3317b100678bbf16027505e22403996c1"},
      {:broadway_rabbitmq, "~> 0.7"},
      {:cachex, "~> 3.3"},
      {:cowlib, "~> 2.12.0", override: true},
      {:credo, "~> 1.3", only: [:dev, :test]},
      {:decorator, "~> 1.2"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.5"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_machina, "~> 2.4", only: :test},
      {:hackney, "~> 1.16"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2", override: true},
      {:logger_json, github: "Nebo15/logger_json", ref: "8e4290a"},
      {:mox, "~> 1.0", only: :test},
      {:postgrex, "~> 0.15.7"},
      {:saxy, "~> 1.1"},
      {:spandex_datadog, "~> 1.1"},
      {:spandex, "~> 3.0.3"},
      {:telemetry, "~> 0.4"},
      {:gun, "2.0.0", hex: :grpc_gun, override: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
