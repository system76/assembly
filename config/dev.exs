use Mix.Config

config :Assembly, Assembly.Repo,
  username: "postgres",
  password: "postgres",
  database: "assembly_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
