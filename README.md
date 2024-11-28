# server-bench

This repository is a companion repo to a [blog post] where I dig into load testing and profiling two different web server implementations for my personal website and blog.

This repository provides:

- A [`nixosConfiguration`](./vm.nix) for a VM named `benchvm`
- Packages for:
  - [`benchvm-test`](./scripts/benchvm-test): A shell script for running k6test against a given web server implementation inside the VM
  - [`benchvm-exec`](./scripts/benchvm-exec): A helper for running a command over SSH in the VM
  - [`k6test`](./scripts/k6test): A package that wraps a shell script and K6 script to execute a specific load test with [`k6`](https://k6.io/)
  - [`parca`](./parca/parca.nix): A continuous profiling tool (this [should be upstream](https://github.com/NixOS/nixpkgs/pull/359635) in [nixpkgs](https://github.com/NixOS/nixpkgs) by the time the blog lands!)
- An example [Parca config file](./parca/parca.yaml) for profiling a server with a `pprof` endpoint listening on `localhost:6060`

## Usage

```shell
# Build & run the VM
❯ nix run github:jnsgruk/server-bench#benchvm -- --daemonize --display none

# Edit the core/memory count as required
❯ vim vm.nix

# Start, and load test a server, choosing your variety
❯ nix run github:jnsgruk/server-bench#benchvm-test -- <jnsgruk-go-old|jnsgruk-go|jnsgruk-rust>

# Power down the VM
❯ nix run github:jnsgruk/server-bench#benchvm-exec -- poweroff
```

The results will be gathered in a collection of `summary-*.<txt|html|json>` files for you to inspect.

For more details, see the [blog post]!

[blog post]: https://jnsgr.uk/2024/12/experiments-with-rust-nix-k6-parca/
