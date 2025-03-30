# containerized-nix

Run Nix locally in a container.

Usage:

1. `. bin/project-set-env.sh`
2. `deploy-nixos.sh`
3. `docker exec -ti nix nix profile install nixpkgs#rsync`