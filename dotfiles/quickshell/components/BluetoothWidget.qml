import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Style.js" as Style

Item {
    id: root

    required property var shellScreen

    property bool bluetoothOpen: false
    property real iconSize: 16
    property string statusMessage: ""

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool scanning: enabled && adapter.discovering

    signal opened()

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: bluetoothOpen
        onActivated: closePopup()
    }

    HyprlandFocusGrab {
        windows: [bluetoothPopupWindow]
        active: root.bluetoothOpen
        onCleared: root.closePopup()
    }

    width: bluetoothIcon.implicitWidth
    height: bluetoothIcon.implicitHeight
    visible: available

    function closePopup() {
        bluetoothOpen = false
    }

    function togglePopup() {
        bluetoothOpen = !bluetoothOpen
        if (bluetoothOpen) {
            opened()
        }
    }

    function toggleBluetooth() {
        if (!available) return
        statusMessage = ""
        adapter.enabled = !adapter.enabled
    }

    function toggleDiscovery() {
        if (!available || !enabled) {
            statusMessage = "Turn Bluetooth on before scanning"
            return
        }

        statusMessage = ""
        adapter.discovering = !adapter.discovering
    }

    Text {
        id: bluetoothIcon
        anchors.centerIn: parent
        text: enabled ? "󰂯" : "󰂲"
        color: Style.barIcon
        font.family: Style.monoFont
        font.pixelSize: root.iconSize

        MouseArea {
            anchors.fill: parent
            onClicked: togglePopup()
        }
    }

    PanelWindow {
        id: bluetoothPopupWindow

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
                        text: !available ? "Unavailable" : scanning ? "Scanning" : enabled ? "On" : "Off"
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
                        color: powerMouse.pressed ? Style.selected : enabled ? Style.enabled : Style.disabled
                        border.color: Style.border
                        border.width: Style.borderWidth
                        opacity: 1

                        Text {
                            anchors.centerIn: parent
                            text: enabled ? "Turn off" : "Turn on"
                            color: Style.foreground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            enabled: available
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
                    visible: !available
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
