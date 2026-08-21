pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    readonly property real textSize: settings.textSize

    function setTextSize(value) {
        settings.textSize = value
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("settings.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: settings
            property real textSize: 14
        }
    }
}
