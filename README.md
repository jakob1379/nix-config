ñ# Nix Config

This repository contains Nix configuration files for setting up and managing
development environments.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->

**Table of Contents**

- [Nix Config](#nix-config)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Makefile](#makefile)
  - [Development Shell (devShell)](#development-shell-devshell)
  - [Features](#features)
  - [Contributing](#contributing)
  - [License](#license)

<!-- markdown-toc end -->

## Installation

Clone the repository:

```bash
git clone https://github.com/jakob1379/nix-config.git
cd nix-config
```

## Usage

Apply the configurations by running the provided scripts or commands. Review
individual configuration files for details.

## Makefile

The `Makefile` includes targets to install Nix and Home Manager:

- **`make install`**: Installs Nix and Home Manager, and sets up necessary configurations.

## Development Shell (devShell)

The `devShell` provides a consistent development environment:

- **Packages**: Uses `generalPackages` for essential tools.
- **Build Inputs**: Includes `pkgs.pre-commit` for managing pre-commit hooks.
- **Shell Hook**: Sets the `PATH` for local Node.js binaries and customizes the
  shell prompt.
- **Post Build**: Installs and updates pre-commit hooks.

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
