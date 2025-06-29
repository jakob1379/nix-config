.PHONY: install install-nix

install: install-nix

install-nix:
	@if ! command -v nix &> /dev/null; then \
		echo "Installing nix"; \
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; \
	else \
		echo "Nix is already installed."; \
	fi

	@echo "Ensuring Nix is configured for flakes..."
	@mkdir -p ~/.config/nix
	@CONFIG_FILE=~/.config/nix/nix.conf; \
	touch $$CONFIG_FILE; \
	if ! grep -q "experimental-features" "$$CONFIG_FILE"; then \
		echo "Appending experimental-features to $$CONFIG_FILE..."; \
		echo "experimental-features = nix-command flakes" >> "$$CONFIG_FILE"; \
	else \
		echo "Nix experimental features already configured in $$CONFIG_FILE."; \
	fi
