# Repository instructions

## Nix builds and binary sources

- Use signed Nix substitutes for packages whenever possible. Prefer stock Nixpkgs derivations so their store paths match `https://cache.nixos.org`. Put local configuration in modules or lightweight wrappers.
- Run `nixos-rebuild dry-build --flake .#LOQ` after changing packages or `flake.lock`. If an application or dependency would compile from source, find a trusted prebuilt option or report the cache miss before building. Local assembly of system configuration and wrappers is expected.
- Keep Nix signature verification enabled. Verify the publisher and public signing key before adding a third-party cache.
- For software packaged from a vendor binary, use the official versioned release and pin the exact asset's SHA-256. Check signatures or signed checksums when the publisher provides them. A checksum verifies the bytes against the pin. Trust in the binary comes from its provenance. Investigate an unexpected hash change for an already pinned release before accepting it.

## Updating Hex and T3 Code Nightly

Run `./scripts/update-package hex --version VERSION` or `./scripts/update-package t3code-nightly --version VERSION`. The updater pins the official release asset, and for Hex it also updates the matching Home Manager input and lock entry. Review the diff and run the LOQ dry build before building the package and activating the configuration.
