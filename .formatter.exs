[
  import_deps: [:ecto, :ecto_enum, :ecto_sql, :grpc],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 120
]
