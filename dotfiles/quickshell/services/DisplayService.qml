pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real brightness: 50

    function refresh() {
        if (!readBrightness.running) readBrightness.running = true
    }

    function setBrightness(value) {
        brightness = value
        setBrightnessProcess.running = true
    }

    Process {
        id: readBrightness
        command: ["bash", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = Number(String(text).trim())
                if (!isNaN(value) && value > 0) root.brightness = value
            }
        }
    }

    Process {
        id: setBrightnessProcess
        command: ["brightnessctl", "-e4", "-n2", "set", Math.round(root.brightness) + "%"]
    }
}
