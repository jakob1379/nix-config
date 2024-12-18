# this is a makefile, define the install section and phony for installing and setting up multi-user nix
# and home-manager following this guide https://nix-community.github.io/home-manager/index.xhtml

# phony section
.PHONY: install install-nix install-home-manager

install: install-nix install-home-manager

install-nix:
	@if ! command -v nix &> /dev/null; then \
		echo "Installing nix"; \
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; \
	else \
		echo "Nix is already installed."; \
	fi

	@mkdir -p ~/.config/nix && \
	echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf && \
	echo "Enabled experimental features for Nix: nix-command and flakes."

install-home-manager:
	@echo "Installing home-manager"
	@nix-channel --add https://github.com/nix-community/home-manager/archive/release-unstable.tar.gz home-manager
	@nix-channel --update
	@nix-shell '<home-manager>' -A install
