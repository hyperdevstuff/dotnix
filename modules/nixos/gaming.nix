{ pkgs, username, ... }:

let
  # Sekiro is hard-capped at 60 FPS, so the P-cores never need to boost to
  # 4.4 GHz. Measurements on this LOQ at 3.6 GHz still showed 85-97 °C in
  # gameplay, so the gaming profile is 3.2 GHz + a sane package power cap.
  # Tune from the command line without rebuilding:
  #   sudo cpu-cap game 3000 2400 35 50   # P MHz, E MHz, PL1 W, PL2 W
  cpuCap = pkgs.writeShellApplication {
    name = "cpu-cap";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused ];
    text = ''
      # Cap CPU frequency and package power while gaming, then restore the
      # firmware values on exit. P-cores (0-7 on this i5-12450HX) get one
      # frequency limit, E-cores (8-11) another. Limits are applied per
      # cpufreq policy because intel_pstate exposes one policy per logical
      # CPU here.
      state_file=/run/cpu-cap.state
      rapl_dir=/sys/class/powercap/intel-rapl:0
      p_max=''${CPU_CAP_P_MAX:-3200000}
      e_max=''${CPU_CAP_E_MAX:-2600000}
      pl1=''${CPU_CAP_PL1:-45000000}
      pl2=''${CPU_CAP_PL2:-65000000}

      cmd=''${1:-game}
      shift || true

      state_get() {
        sed -n "s/^$1=//p" "$state_file"
      }

      expand_cpu_list() {
        local spec=$1 part a b i
        local -a out=() parts
        IFS=',' read -r -a parts <<< "$spec"
        for part in "''${parts[@]}"; do
          if [[ $part == *-* ]]; then
            a=''${part%%-*}
            b=''${part##*-}
            for ((i = a; i <= b; i++)); do out+=("$i"); done
          else
            out+=("$part")
          fi
        done
        printf '%s ' "''${out[@]}"
      }

      p_cpus=" $(expand_cpu_list "$(cat /sys/devices/cpu_core/cpus 2>/dev/null || echo 0-7)")"

      policy_target() {
        local policy=$1 cpu is_p=0
        local -a policy_cpus
        read -r -a policy_cpus <<< "$(cat "$policy/affected_cpus")"
        for cpu in "''${policy_cpus[@]}"; do
          if [[ $p_cpus == *" $cpu "* ]]; then is_p=1; fi
        done
        if (( is_p )); then echo "$p_max"; else echo "$e_max"; fi
      }

      restore_rapl() {
        local key=$1 value
        value=$(state_get "$key")
        [[ -n $value ]] || return 0
        case $key in
          rapl_pl2) echo "$value" > "$rapl_dir/constraint_1_power_limit_uw" 2>/dev/null || true ;;
          rapl_pl1) echo "$value" > "$rapl_dir/constraint_0_power_limit_uw" 2>/dev/null || true ;;
        esac
      }

      case $cmd in
        game)
          if [[ -n ''${1:-} ]]; then p_max=$(( $1 * 1000 )); fi
          if [[ -n ''${2:-} ]]; then e_max=$(( $2 * 1000 )); fi
          if [[ -n ''${3:-} ]]; then pl1=$(( $3 * 1000000 )); fi
          if [[ -n ''${4:-} ]]; then pl2=$(( $4 * 1000000 )); fi

          if [[ ! -f $state_file ]]; then
            : > "$state_file"
            # RAPL is stored PL2 first so reset can restore it before PL1.
            if [[ -r $rapl_dir/constraint_1_power_limit_uw ]]; then
              printf 'rapl_pl2=%s\n' "$(cat "$rapl_dir/constraint_1_power_limit_uw")" >> "$state_file"
              printf 'rapl_pl1=%s\n' "$(cat "$rapl_dir/constraint_0_power_limit_uw")" >> "$state_file"
            fi
            for policy in /sys/devices/system/cpu/cpufreq/policy*; do
              printf '%s=%s\n' "$(basename "$policy")" \
                "$(cat "$policy/scaling_max_freq")" >> "$state_file"
            done
          fi

          for policy in /sys/devices/system/cpu/cpufreq/policy*; do
            target=$(policy_target "$policy")
            stock=$(cat "$policy/cpuinfo_max_freq")
            if (( target < stock )); then
              echo "$target" > "$policy/scaling_max_freq" 2>/dev/null || true
            fi
          done

          if [[ -w $rapl_dir/constraint_1_power_limit_uw ]]; then
            orig_pl2=$(state_get rapl_pl2)
            orig_pl1=$(state_get rapl_pl1)
            if [[ -n $orig_pl2 && -n $orig_pl1 ]]; then
              if (( pl2 > orig_pl2 )); then pl2=$orig_pl2; fi
              if (( pl1 > orig_pl1 )); then pl1=$orig_pl1; fi
              if (( pl2 < pl1 )); then pl2=$pl1; fi
              echo "$pl2" > "$rapl_dir/constraint_1_power_limit_uw" 2>/dev/null || true
              echo "$pl1" > "$rapl_dir/constraint_0_power_limit_uw" 2>/dev/null || true
            fi
          fi

          echo "cpu-cap: P-cores <= $((p_max / 1000)) MHz, E-cores <= $((e_max / 1000)) MHz, PL1 $((pl1 / 1000000)) W, PL2 $((pl2 / 1000000)) W"
          ;;
        reset)
          if [[ -f $state_file ]]; then
            restore_rapl rapl_pl2
            restore_rapl rapl_pl1
            while IFS='=' read -r name value; do
              case $name in
                policy*)
                  echo "$value" > "/sys/devices/system/cpu/cpufreq/$name/scaling_max_freq" \
                    2>/dev/null || true
                  ;;
              esac
            done < "$state_file"
            rm -f "$state_file"
            echo "cpu-cap: restored stock CPU limits"
          fi
          ;;
        status)
          for policy in /sys/devices/system/cpu/cpufreq/policy*; do
            printf '%-10s max=%-8s now=%s\n' "$(basename "$policy")" \
              "$(cat "$policy/scaling_max_freq")" \
              "$(cat "$policy/scaling_cur_freq" 2>/dev/null || echo n/a)"
          done
          if [[ -r $rapl_dir/constraint_0_power_limit_uw ]]; then
            printf 'PL1=%s W  PL2=%s W\n' \
              "$(( $(cat "$rapl_dir/constraint_0_power_limit_uw") / 1000000 ))" \
              "$(( $(cat "$rapl_dir/constraint_1_power_limit_uw") / 1000000 ))"
          else
            echo "PL1/PL2: run with sudo to read"
          fi
          ;;
        *)
          echo "usage: cpu-cap [game [p_mhz e_mhz pl1_w pl2_w] | reset | status]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ cpuCap ];

  # GameMode runs these around a game started with `gamemoderun` (Lutris
  # enables that per game). NOPASSWD is scoped to this one helper.
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${cpuCap}/bin/cpu-cap";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # gamemoded's PATH does not include /run/current-system/sw/bin (it is just
  # the pkexec wrapper), and /run/current-system/sw/bin/sudo is not setuid,
  # so the hook must call the setuid wrapper by absolute path.
  programs.gamemode.settings.custom = {
    start = "/run/wrappers/bin/sudo -n ${cpuCap}/bin/cpu-cap game";
    end = "/run/wrappers/bin/sudo -n ${cpuCap}/bin/cpu-cap reset";
  };

  # Gamescope gives the game its own nested Xwayland session, so Wine owns
  # the cursor inside it instead of racing niri's cursor through
  # xwayland-satellite (that race is what showed a Bibata cursor and Wine's
  # cursor at the same time in Sekiro's menus). It also pins the game to a
  # fixed 1920x1080@60 output, which keeps VRR/fractional scaling out of the
  # picture. Lutris launches it when the per-game "Enable Gamescope" option
  # is set (see sekiro-shadows-die-twice-local.yml).
  #
  # Deliberately no capSysNice: Lutris runs inside bubblewrap with
  # no_new_privs, so a capability wrapper is stripped at exec and gamescope
  # dies with "failed to inherit capabilities: Operation not permitted".
  # Gamescope runs fine without realtime priority.
  programs.gamescope.enable = true;

  # Optional: a sched_ext scheduler that understands Intel P/E cores. It
  # improves 1% lows and frame pacing on hybrid CPUs. Uncomment, rebuild,
  # and keep whichever of scx_lavd / scx_bpfland feels smoother:
  #
  # services.scx-loader = {
  #   enable = true;
  #   config.default_sched = "scx_lavd";
  # };
}
