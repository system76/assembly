<div align="center">
  <h1>Assembly</h1>
  <h3>An assembly management microservice</h3>
  <br>
  <br>
</div>

---

This repository contains the code that controls our assembly fulfillment. This
includes:

- Calculating how many components we need for building all orders
- Persisting build information into the database
- Calculating if a build can be built by component quantity in real time

## Communication

This micro service works very closely with (and is dependent on)
[the Warehouse service](https://github.com/system76/warehouse). The warehouse
service is responsible for tracking the amount of available components in our
warehouse. They have a relationship like so:

```
Assembly ------------------------------------------------------------> Warehouse

This is a gRPC request from Assembly to Warehouse to determine the
`Warehouse.Schema.Component` quantity available. This is used to determine if a
`Assembly.Schemas.Build` has all of the needed parts in stock to build. A
similar RabbitMQ message is broadcasted when that quantity changes.

Assembly <------------------------------------------------------------ Warehouse

This is a gRPC request from Warehouse to Assembly to determine the demand of
`Warehouse.Schema.Component`. This allows Warehouse to determine the back order
status of a `Warehouse.Schema.Sku` and the quantity we need to order. A similar
RabbitMQ message is broadcasted when this quantity changes.
```

Like wise, this micro service is connected into our order system to create and
update builds when changes on an order occur.

## Schemas

This micro service has a small subset of data it works with.

`Assembly.Schemas.Build` represents the smallest building item on an order. For
instance, this could be a single keyboard what we could potentially ship out
separately, or a whole desktop. If you order multiple quantities, multiple
builds will be created.

`Assembly.Schemas.Option` is a selected option for that build. Some products
have no options, while others have many. A Thelio desktop for instance has many
options to select, like the GPU, CPU, etc.

## Development Setup

First, make sure you are running the dependency services with `docker-compose`:

```shell
docker-compose up
```

Tools and language versions required for development can be installed with [asdf](https://github.com/asdf-vm/asdf):

```shell
# Install asdf plugins
asdf plugin-add grpcurl https://github.com/asdf-community/asdf-grpcurl.git
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
# Install required tool versions on this project directory
# Only needed once, getting into this directory will make asdf automatically
# activate the versions from .tool-versions.
asdf install
```

Read more on [http://asdf-vm.com/](http://asdf-vm.com/) for usage information.

Dependencies are managed via `mix`. In the repo, run:

```shell
mix deps.get
```

Then run this to test the project:

```shell
mix test
```

### Contributing

This project makes use of [https://pre-commit.com/](https://pre-commit.com/) to ensure code quality before pushing it to Git. While this is not a requirement, it's encouraged to have `pre-commit` installed with `pip install pre-commit`, and the in this project root, run:

```shell
pre-commit install
```
