<div align="center">
  <h1>Assembly</h1>
  <h3>An assembly management microservice</h3>
  <br>
  <br>
</div>

---

![](https://github.com/system76/assembly/workflows/Continuous%20Integration/badge.svg)

This repository contains the code that controls our assembly fulfillment. This
includes telling if we have enough parts to build a build, and persisting
saved build information.

## Commands

* `mix ecto.reset` - Resets, migrates, and seeds the development database
* `mix test` - Runs tests

## Setup

First, make sure you are running the dependency services with `docker-compose`:

```shell
docker-compose up
```

Dependencies are managed via `mix`. In the repo, run:

```shell
mix deps.get
```

Then run this to setup your development database:

```shell
mix ecto.create
mix ecto.reset
```
