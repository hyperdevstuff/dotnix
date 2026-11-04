import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 30
        color: "#1e1e2e"

        property string cpu: "--"
        property string mem: "--"
        property string battery: "--"
        property string network: "offline"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Process {
            id: launcher
            command: ["fuzzel"]
        }

        Process {
            id: stats
            running: true
            command: [
                "/bin/sh",
                "-c",
                "prev=0; previ=0; while true; do set -- $(head -n1 /proc/stat); total=$(($2+$3+$4+$5+$6+$7+$8+$9)); idle=$(($5+$6)); cpu=0; if [ $prev -gt 0 ]; then dt=$((total-prev)); di=$((idle-previ)); if [ $dt -gt 0 ]; then cpu=$((100*(dt-di)/dt)); fi; fi; prev=$total; previ=$idle; mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print int(100*(t-a)/t)}' /proc/meminfo); bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); [ -z $bat ] && bat=--; net=offline; for f in /sys/class/net/wl* /sys/class/net/en*; do [ -e $f/operstate ] || continue; if [ $(cat $f/operstate) = up ]; then net=$(basename $f); break; fi; done; echo $cpu $mem $bat $net; sleep 2; done"
            ]

            stdout: SplitParser {
                onRead: line => {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 4) {
                        bar.cpu = parts[0];
                        bar.mem = parts[1];
                        bar.battery = parts[2];
                        bar.network = parts[3];
                    }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 14

            Rectangle {
                implicitWidth: 58
                implicitHeight: 20
                radius: 5
                color: launcherHover.hovered ? "#313244" : "#181825"

                Text {
                    anchors.centerIn: parent
                    text: "apps"
                    color: "#cba6f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                HoverHandler { id: launcherHover }

                TapHandler {
                    onTapped: launcher.startDetached()
                }
            }

            Text {
                text: "nixos"
                color: "#a6e3a1"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd dd MMM   HH:mm")
                color: "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "CPU " + bar.cpu + "%"
                color: "#89b4fa"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Text {
                text: "RAM " + bar.mem + "%"
                color: "#f9e2af"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Text {
                text: "BAT " + bar.battery + "%"
                color: "#a6e3a1"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Text {
                text: bar.network
                color: "#94e2d5"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }
    }
}
