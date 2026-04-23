# Nix Config

This repository contains Nix configuration files for setting up and managing
development environments.

**Table of Contents**

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Layout](#layout)
- [Installation](#installation)
- [Usage](#usage)
- [Install Script](#install-script)
- [Development Shell (devShell)](#development-shell-devshell)
- [Features](#features)
- [Contributing](#contributing)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Layout

- `home/`: Home Manager entrypoints, shared modules, and user-space system
  profiles.
- `nixos/hosts/`: machine-specific NixOS configurations.
- `nixos/users/`: user-specific NixOS modules that hosts can opt into.
- `lib/`: flake helpers and shared constructors.
- `devshells/`: development shells exported by the flake.

## Installation

Clone the repository:

```bash
git clone https://github.com/jakob1379/nix-config.git
cd nix-config
```

## Usage

Apply the configurations by running the provided scripts or commands. Review
individual configuration files for details.

## Install Script

The `install.sh` script installs Nix if needed and enables the required flake
configuration:

- **`./install.sh`**: Installs Nix when missing and ensures
  `~/.config/nix/nix.conf` enables flakes.

## Development Shell (devShell)

The `devShell` provides a consistent development environment:

- **Packages**: Uses `generalPackages` for essential tools.
- **Hook Tooling**: Uses `cachix/git-hooks.nix` to generate and install prek
  hooks from `nix/git-hooks.nix`.
- **Shell Hook**: Installs hooks, sets `SSL_CERT_FILE`, and customizes the shell
  prompt.

Run all hooks through Nix with:

```bash
nix develop -c prek run --all-files
```

Enter the development shell with:

```bash
nix develop

# or automatically with direnv
direnv allow
```

## Features

- Comprehensive Nix configurations.
- Setup scripts.
- Support for multiple system installations.

## Contributing

Contributions are welcome! Fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file
for details.

Explore the repository and customize the configurations to fit your needs!
