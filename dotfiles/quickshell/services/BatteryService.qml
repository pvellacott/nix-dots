pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int percent: -1
    property string state: ""

    readonly property bool available: percent >= 0
    readonly property bool charging: state.toLowerCase().indexOf("charg") !== -1

    Process {
        id: readBattery

        command: ["bash", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && printf '%s %s' \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\" 2>/dev/null)\" && exit; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = String(text).trim().split(/\s+/)
                var value = Number(parts[0])
                root.percent = parts[0] !== "" && !isNaN(value) ? value : -1
                root.state = root.available ? parts.slice(1).join(" ") : ""
            }
        }
    }

    Timer {
        interval: 30000
        running: root.available
        repeat: true
        onTriggered: if (!readBattery.running) readBattery.running = true
    }

    Component.onCompleted: readBattery.running = true
}
