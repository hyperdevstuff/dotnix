_:

{
  # niri is not a desktop environment: `security.polkit.enable` only provides
  # the daemon. notchD registers its own PolkitAgent (Quickshell.Services.Polkit)
  # and draws the authentication prompt in the island, so no external agent is
  # started here. Running polkit-gnome as well would make the two agents race
  # for every request.
}
