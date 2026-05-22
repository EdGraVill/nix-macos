{ ... }:

{
  system.activationScripts.energy.text = ''
    # Power adapter: keep the Mac available and awake.
    /usr/bin/pmset -c sleep 0 || true
    /usr/bin/pmset -c disksleep 0 || true
    /usr/bin/pmset -c displaysleep 0 || true

    # Disable wake-on-network access as requested.
    /usr/bin/pmset -a womp 0 || true

    # Disable hibernation behavior.
    /usr/bin/pmset -a hibernatemode 0 || true

    # Restart automatically if the computer freezes.
    /usr/sbin/systemsetup -setrestartfreeze on >/dev/null 2>&1 || true
  '';
}
