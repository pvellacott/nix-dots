import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Style.js" as Style

Item {
    id: root

    required property var shellScreen

    property bool bluetoothOpen: false
    property bool powered: false
    property bool discovering: false
    property string powerTarget: "on"
    property string statusMessage: ""


    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: powered
    readonly property bool scanning: enabled && available && (discovering || adapter.discovering)

    signal opened()

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: bluetoothOpen
        onActivated: closePopup()
    }

    width: bluetoothIcon.implicitWidth
    height: bluetoothIcon.implicitHeight

    function closePopup() {
        bluetoothOpen = false
    }

    function togglePopup() {
        bluetoothOpen = !bluetoothOpen
        if (bluetoothOpen) {
            opened()
            readController.running = true
        }
    }

    function toggleBluetooth() {
        if (togglePower.running) return
        powerTarget = enabled ? "off" : "on"
        statusMessage = ""
        if (powerTarget === "off") discovering = false
        togglePower.running = true
    }

    function toggleDiscovery() {
        if (!enabled) {
            statusMessage = "Turn Bluetooth on before scanning"
            return
        }

        statusMessage = ""
        adapter.discovering = !adapter.discovering
    }

    function updateControllerState(output) {
        var text = String(output)
        if (text.indexOf("Soft blocked: yes") !== -1) powered = false
        else if (text.indexOf("Powered: yes") !== -1) powered = true
        else if (text.indexOf("Powered: no") !== -1) powered = false
        else if (text.indexOf("No default controller") !== -1) powered = false

        if (text.indexOf("Discovering: yes") !== -1) discovering = true
        else if (text.indexOf("Discovering: no") !== -1) discovering = false
        else if (!powered) discovering = false
    }

    Process {
        id: readController
        command: ["bash", "-lc", "rfkill list bluetooth; bluetoothctl show 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: updateControllerState(text)
        }
    }

    Process {
        id: togglePower
        command: powerTarget === "off"
            ? ["bash", "-lc", "bluetoothctl power off; rfkill block bluetooth"]
            : ["bash", "-lc", "rfkill unblock bluetooth; sleep 1; bluetoothctl power on"]
        stdout: StdioCollector {
            onStreamFinished: {
                statusMessage = String(text).trim()
                readController.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                statusMessage = String(text).trim()
                readController.running = true
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!readController.running) readController.running = true
    }

    Text {
        id: bluetoothIcon
        anchors.centerIn: parent
        text: enabled ? "󰂯" : "󰂲"
        color: Style.barIcon
        font.family: Style.monoFont
        font.pixelSize: 16

        MouseArea {
            anchors.fill: parent
            onClicked: togglePopup()
        }
    }

    PanelWindow {
        screen: root.shellScreen
        visible: root.bluetoothOpen
        implicitWidth: 320
        implicitHeight: scanning ? 360 : statusMessage.length > 0 ? 160 : 132
        anchors { top: true; right: true }
        margins { top: 42; right: 12 }
        color: "transparent"

        WlrLayershell.namespace: "bluetooth-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: if (visible) bluetoothPopup.forceActiveFocus()

        Rectangle {
            id: bluetoothPopup

            anchors.fill: parent
            focus: root.bluetoothOpen
            radius: Style.radius
            color: Style.popupBackground
            border.color: Style.border
            border.width: Style.borderWidth

            Keys.onEscapePressed: root.closePopup()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.padding
                spacing: Style.spacing

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Bluetooth"
                        color: Style.foreground
                        font.family: Style.uiFont
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: scanning ? "Scanning" : enabled ? "On" : "Off"
                        color: Style.mutedForeground
                        font.family: Style.monoFont
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 28
                        radius: 14
                        color: togglePower.running || powerMouse.pressed ? Style.selected : enabled ? Style.enabled : Style.disabled
                        border.color: Style.border
                        border.width: Style.borderWidth
                        opacity: 1

                        Text {
                            anchors.centerIn: parent
                            text: togglePower.running ? "Working" : enabled ? "Turn off" : "Turn on"
                            color: Style.foreground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            enabled: !togglePower.running
                            onClicked: toggleBluetooth()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 28
                        radius: 14
                        color: scanMouse.pressed || scanning ? Style.selected : Style.enabled
                        border.color: Style.border
                        border.width: Style.borderWidth
                        opacity: enabled ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: scanning ? "Stop scan" : "Scan"
                            color: Style.foreground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            enabled: enabled
                            onClicked: toggleDiscovery()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !available && enabled
                    text: "No Bluetooth adapter found"
                    color: Style.mutedForeground
                    font.family: Style.uiFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: statusMessage.length > 0
                    text: statusMessage
                    color: Style.mutedForeground
                    font.family: Style.uiFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    visible: scanning
                    color: Style.inactiveBorder
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: scanning
                    clip: true
                    spacing: 6
                    model: available ? adapter.devices : []

                    delegate: Rectangle {
                        required property var modelData

                        readonly property var device: modelData

                        width: ListView.view.width
                        height: 34
                        radius: 6
                        color: device && device.connected ? Style.selected : "transparent"
                        border.color: device && device.connected ? Style.border : Style.inactiveBorder
                        border.width: Style.borderWidth

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                text: device && device.connected ? "󰂱" : "󰂯"
                                color: device && device.connected ? Style.foreground : Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: device ? (device.name || device.deviceName || device.address) : "Unknown device"
                                color: device && device.connected ? Style.foreground : Style.mutedForeground
                                font.family: Style.uiFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: device && device.batteryAvailable && device.battery !== null && device.battery !== undefined
                                text: visible ? Math.round(device.battery * 100) + "%" : ""
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!device) return
                                if (device.connected) device.disconnect()
                                else if (device.paired) device.connect()
                                else device.pair()
                            }
                        }
                    }
                }
            }
        }
    }
}
