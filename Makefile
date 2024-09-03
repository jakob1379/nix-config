# this is a makefile, define the install section and phony for installing and setting up multi-user nix
# and home-manager following this guide https://nix-community.github.io/home-manager/index.xhtml

# phony section
.PHONY: install install-nix install-home-manager

install: install-nix install-home-manager

install-nix:
	@echo "Installing nix"
	@curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

install-home-manager:
	@echo "Installing home-manager"
        @. "~/.nix-profile/etc/profile.d/hm-session-vars.sh"
	@nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	@nix-channel --update
	@nix-shell '<home-manager>' -A install

	@echo "setting .profile to source nix-profile"
	@echo "if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi" >> ~/.profile
