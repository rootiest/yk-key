# yk-key

Manage YubiKey GPG signing keys and the Git signing key from any POSIX shell

## Setup

Clone the repository and enter it:

```sh
git clone <repository-url> yk-key
cd yk-key
git config core.hooksPath .githooks
```

Describe any further setup (dependencies, environment variables by name, services) here.

## Build and test

- Build: document the build command here (or state that there is no build step).
- Test: `./tests/run-tests.sh`. CI runs the same command.

## Conventions

This project follows the Rootiest project conventions: branch before editing, never
push `main`, Conventional Commits, labeled PRs, docs as the single source of truth.
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Documentation

Project documentation lives in [docs/](docs/README.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Released under the AGPL-3.0-or-later license. See [LICENSE](LICENSE).
