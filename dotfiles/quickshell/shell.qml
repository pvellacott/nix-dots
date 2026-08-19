import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "components/Style.js" as Style

ShellRoot {
    id: root

    property bool isLaptop: true
    property bool volumeOpen: false
    property bool brightnessOpen: false
    property real brightnessValue: 50
    property real textSize: 13
    property int batteryPercent: -1
    property string batteryState: ""
    property int targetWorkspace: 1
    property bool wallpaperAvailable: false

    readonly property bool showBattery: isLaptop && batteryPercent >= 0
    readonly property bool batteryCharging: batteryState.toLowerCase().indexOf("charg") !== -1
    readonly property string currentBatteryIcon: batteryIcon()

    function batteryIcon() {
        if (batteryCharging) return "󰂄"
        if (batteryPercent <= 10) return "󰁺"
        if (batteryPercent <= 25) return "󰁻"
        if (batteryPercent <= 50) return "󰁾"
        if (batteryPercent <= 75) return "󰂀"
        return "󰁹"
    }

    function closePopups() {
        volumeOpen = false
        brightnessOpen = false
    }

    function audioNodeLabel(node) {
        if (!node) return "Unavailable"
        return node.nickname || node.description || node.name || "Unknown device"
    }

    function snapTextSize(value) {
        var sizes = [9, 10, 11, 12, 14, 16, 20]
        var closest = sizes[0]
        var closestDistance = Math.abs(value - closest)

        for (var i = 1; i < sizes.length; i++) {
            var distance = Math.abs(value - sizes[i])
            if (distance < closestDistance) {
                closest = sizes[i]
                closestDistance = distance
            }
        }

        return closest
    }

    function switchWorkspace(workspace) {
        targetWorkspace = workspace
        if (!switchWorkspaceProcess.running) switchWorkspaceProcess.running = true
    }

    Process {
        id: switchWorkspaceProcess
        command: ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + String(targetWorkspace) + " })"]
    }

    Process {
        id: readBattery
        command: ["bash", "-lc", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && printf '%s %s' \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\" 2>/dev/null)\" && exit; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = String(text).trim().split(/\s+/)
                var percent = Number(parts[0])
                if (!isNaN(percent)) {
                    batteryPercent = percent
                    batteryState = parts.slice(1).join(" ")
                }
            }
        }
    }

    Process {
        command: ["test", "-r", "/home/smoo/Pictures/Wallpapers/snow.png"]
        running: true
        onExited: exitCode => wallpaperAvailable = exitCode === 0
    }

    Timer {
        interval: 30000
        running: isLaptop
        repeat: true
        triggeredOnStart: true
        onTriggered: readBattery.running = true
    }

    Notifications {}

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: volumeOpen || brightnessOpen
        onActivated: closePopups()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: Style.background

            WlrLayershell.namespace: "wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            Image {
                anchors.fill: parent
                source: wallpaperAvailable ? "file:///home/smoo/Pictures/Wallpapers/snow.png" : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            implicitHeight: 28
            anchors { top: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.namespace: "bar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                spacing: 4

                Repeater {
                    model: [1, 2, 3, 4, 5]

                    Rectangle {
                        id: workspaceButton
                        required property int modelData

                        width: 18
                        height: 18
                        radius: 2
                        readonly property bool active: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

                        color: "transparent"
                        border.color: "transparent"
                        border.width: 0

                        Text {
                            anchors.centerIn: parent
                            text: parent.active ? "󰝥" : modelData
                            color: Style.barIcon
                            font.family: Style.monoFont
                            font.pixelSize: parent.active ? 13 : 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.switchWorkspace(workspaceButton.modelData)
                        }
                    }
                }
            }

            Text {
                id: clock
                anchors.centerIn: parent
                color: Style.barIcon
                font.family: Style.monoFont
                font.pixelSize: textSize

                function updateTime() {
                    text = Qt.formatDateTime(new Date(), "dddd HH:mm")
                }

                Component.onCompleted: updateTime()

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.updateTime()
                }
            }

            Row {
                id: volumeWidget

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12
                spacing: 12

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool muted: sink && sink.audio ? sink.audio.muted : true
                readonly property real volume: sink && sink.audio ? sink.audio.volume : 0

                PwObjectTracker { objects: volumeWidget.sink ? [volumeWidget.sink] : [] }

                NetworkWidget {
                    id: networkWidget
                    shellScreen: modelData
                    onOpened: {
                        volumeOpen = false
                        brightnessOpen = false
                        bluetoothWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                BluetoothWidget {
                    id: bluetoothWidget
                    shellScreen: modelData
                    onOpened: {
                        volumeOpen = false
                        brightnessOpen = false
                        networkWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰋋"
                    color: Style.barIcon
                    font.family: Style.monoFont
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                if (volumeWidget.sink && volumeWidget.sink.audio)
                                    volumeWidget.sink.audio.muted = !volumeWidget.sink.audio.muted
                            } else {
                                volumeOpen = !volumeOpen
                                if (volumeOpen) {
                                    brightnessOpen = false
                                    networkWidget.closePopup()
                                    bluetoothWidget.closePopup()
                                    powerWidget.closePopup()
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍹"
                    color: Style.barIcon
                    font.family: Style.monoFont
                    font.pixelSize: 16

                    Process {
                        id: readBrightness
                        command: ["bash", "-lc", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
                        stdout: StdioCollector {
                            onStreamFinished: brightnessValue = Number(String(text).trim()) || brightnessValue
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            brightnessOpen = !brightnessOpen
                            if (brightnessOpen) {
                                volumeOpen = false
                                networkWidget.closePopup()
                                bluetoothWidget.closePopup()
                                powerWidget.closePopup()
                                readBrightness.running = true
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: showBattery
                    text: currentBatteryIcon + " " + batteryPercent + "%"
                    color: Style.barIcon
                    font.family: Style.monoFont
                    font.pixelSize: textSize
                }

                PowerWidget {
                    id: powerWidget
                    shellScreen: modelData
                    onOpened: {
                        volumeOpen = false
                        brightnessOpen = false
                        networkWidget.closePopup()
                        bluetoothWidget.closePopup()
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: volumeOpen
            implicitWidth: 360
            implicitHeight: 380
            anchors { top: true; right: true }
            margins { top: 42; right: 12 }
            color: "transparent"

            WlrLayershell.namespace: "volume-popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore

            onVisibleChanged: if (visible) volumePopup.forceActiveFocus()

            Rectangle {
                id: volumePopup

                anchors.fill: parent
                focus: volumeOpen
                radius: Style.radius
                color: Style.popupBackground
                border.color: Style.border
                border.width: Style.borderWidth

                Keys.onEscapePressed: volumeOpen = false

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property var source: Pipewire.defaultAudioSource
                readonly property real sinkVolume: sink && sink.audio ? sink.audio.volume : 0
                readonly property real sourceVolume: source && source.audio ? source.audio.volume : 0

                PwObjectTracker { objects: [volumePopup.sink, volumePopup.source].filter(function(node) { return node !== null }) }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.padding
                    spacing: Style.spacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Output"
                                color: Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: volumePopup.sink && volumePopup.sink.audio && volumePopup.sink.audio.muted ? "Muted" : Math.round(volumePopup.sinkVolume * 100) + "%"
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: audioNodeLabel(volumePopup.sink)
                            color: Style.mutedForeground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 24
                                radius: 12
                                color: volumePopup.sink && volumePopup.sink.audio && volumePopup.sink.audio.muted ? Style.disabled : Style.enabled
                                border.color: Style.border
                                border.width: Style.borderWidth

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: volumePopup.sink && volumePopup.sink.audio && volumePopup.sink.audio.muted ? "󰝟" : "󰋋"
                                        color: Style.foreground
                                        font.family: Style.monoFont
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: volumePopup.sink && volumePopup.sink.audio && volumePopup.sink.audio.muted ? "Unmute" : "Mute"
                                        color: Style.foreground
                                        font.family: Style.uiFont
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (volumePopup.sink && volumePopup.sink.audio) volumePopup.sink.audio.muted = !volumePopup.sink.audio.muted
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                value: volumePopup.sinkVolume
                                enabled: volumePopup.sink && volumePopup.sink.audio
                                onMoved: if (volumePopup.sink && volumePopup.sink.audio) volumePopup.sink.audio.volume = value
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: Pipewire.nodes

                                Rectangle {
                                    required property var modelData

                                    readonly property var node: modelData
                                    readonly property bool isOutputDevice: node && node.audio && !node.isStream && node.isSink
                                    readonly property bool isSelected: volumePopup.sink && node && volumePopup.sink.id === node.id

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: isOutputDevice ? 28 : 0
                                    visible: isOutputDevice
                                    radius: 6
                                    color: isSelected ? Style.selected : "transparent"
                                    border.color: isSelected ? Style.border : Style.inactiveBorder
                                    border.width: Style.borderWidth

                                    PwObjectTracker { objects: node ? [node] : [] }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 9
                                        anchors.rightMargin: 9
                                        text: audioNodeLabel(node)
                                        color: isSelected ? Style.foreground : Style.mutedForeground
                                        font.family: Style.uiFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Pipewire.preferredDefaultAudioSink = node
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Style.inactiveBorder
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Input"
                                color: Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: volumePopup.source && volumePopup.source.audio && volumePopup.source.audio.muted ? "Muted" : Math.round(volumePopup.sourceVolume * 100) + "%"
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: audioNodeLabel(volumePopup.source)
                            color: Style.mutedForeground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 24
                                radius: 12
                                color: volumePopup.source && volumePopup.source.audio && volumePopup.source.audio.muted ? Style.disabled : Style.enabled
                                border.color: Style.border
                                border.width: Style.borderWidth

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: volumePopup.source && volumePopup.source.audio && volumePopup.source.audio.muted ? "󰍭" : "󰍬"
                                        color: Style.foreground
                                        font.family: Style.monoFont
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: volumePopup.source && volumePopup.source.audio && volumePopup.source.audio.muted ? "Unmute" : "Mute"
                                        color: Style.foreground
                                        font.family: Style.uiFont
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (volumePopup.source && volumePopup.source.audio) volumePopup.source.audio.muted = !volumePopup.source.audio.muted
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                value: volumePopup.sourceVolume
                                enabled: volumePopup.source && volumePopup.source.audio
                                onMoved: if (volumePopup.source && volumePopup.source.audio) volumePopup.source.audio.volume = value
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: Pipewire.nodes

                                Rectangle {
                                    required property var modelData

                                    readonly property var node: modelData
                                    readonly property bool isInputDevice: node && node.audio && !node.isStream && !node.isSink
                                    readonly property bool isSelected: volumePopup.source && node && volumePopup.source.id === node.id

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: isInputDevice ? 28 : 0
                                    visible: isInputDevice
                                    radius: 6
                                    color: isSelected ? Style.selected : "transparent"
                                    border.color: isSelected ? Style.border : Style.inactiveBorder
                                    border.width: Style.borderWidth

                                    PwObjectTracker { objects: node ? [node] : [] }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 9
                                        anchors.rightMargin: 9
                                        text: audioNodeLabel(node)
                                        color: isSelected ? Style.foreground : Style.mutedForeground
                                        font.family: Style.uiFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Pipewire.preferredDefaultAudioSource = node
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: brightnessOpen
            implicitWidth: 300
            implicitHeight: 170
            anchors { top: true; right: true }
            margins { top: 42; right: 8 }
            color: "transparent"

            WlrLayershell.namespace: "brightness-popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore

            onVisibleChanged: if (visible) brightnessPopup.forceActiveFocus()

            Rectangle {
                id: brightnessPopup

                anchors.fill: parent
                focus: brightnessOpen
                radius: Style.radius
                color: Style.popupBackground
                border.color: Style.border
                border.width: Style.borderWidth

                Keys.onEscapePressed: brightnessOpen = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.padding
                    spacing: Style.spacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Brightness"
                                color: Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: Math.round(brightnessValue) + "%"
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 12
                            }
                        }

                        Slider {
                            id: brightnessSlider
                            Layout.fillWidth: true
                            from: 1
                            to: 100
                            value: brightnessValue

                            Process {
                                id: setBrightness
                                command: ["brightnessctl", "-e4", "-n2", "set", Math.round(brightnessSlider.value) + "%"]
                            }

                            onMoved: {
                                brightnessValue = value
                                setBrightness.running = true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Style.inactiveBorder
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Text size"
                                color: Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: Math.round(textSize) + "px"
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 12
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Repeater {
                                model: [9, 10, 11, 12, 14, 16, 20]

                                Item {
                                    required property int modelData

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: textSize === modelData ? 18 : 10
                                            Layout.preferredHeight: 3
                                            radius: 2
                                            color: textSize === modelData ? Style.border : Style.inactiveBorder
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData
                                            color: textSize === modelData ? Style.foreground : Style.mutedForeground
                                            font.family: Style.monoFont
                                            font.pixelSize: 9
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: textSize = modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
