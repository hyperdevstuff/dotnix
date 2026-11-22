# Repository instructions

## Nix builds and binary sources

- Use signed Nix substitutes for packages whenever possible. Prefer stock Nixpkgs derivations so their store paths match `https://cache.nixos.org`. Put local configuration in modules or lightweight wrappers.
- Run `nixos-rebuild dry-build --flake .#LOQ` after changing packages or `flake.lock`. If an application or dependency would compile from source, find a trusted prebuilt option or report the cache miss before building. Local assembly of system configuration and wrappers is expected.
- Keep Nix signature verification enabled. Verify the publisher and public signing key before adding a third-party cache.
- For software packaged from a vendor binary, use the official versioned release and pin the exact asset's SHA-256. Check signatures or signed checksums when the publisher provides them. A checksum verifies the bytes against the pin. Trust in the binary comes from its provenance. Investigate an unexpected hash change for an already pinned release before accepting it.

## Updating Hex

Use the SHA-256 for the official `hex-<version>-linux-x64.deb` asset. Convert GitHub's hex digest with `nix hash convert --hash-algo sha256 --to sri`, then update `version` and `src.hash` in `pkgs/hex-bin.nix`. Set the Hex input in `flake.nix` to the matching `v<version>` tag and run `nix flake update hex` to refresh its lock entry. Build `.#hex-bin` and run the LOQ dry build before activation.
