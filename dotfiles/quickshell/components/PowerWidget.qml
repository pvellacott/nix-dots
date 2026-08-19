import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Style.js" as Style

Item {
    id: root

    required property var shellScreen

    property bool powerOpen: false
    property string pendingAction: ""

    signal opened()

    width: powerIcon.implicitWidth
    height: powerIcon.implicitHeight

    function closePopup() {
        powerOpen = false
    }

    function togglePopup() {
        powerOpen = !powerOpen
        if (powerOpen) opened()
    }

    function runAction(action) {
        pendingAction = action
        closePopup()
        actionProcess.running = true
    }

    function commandForAction(action) {
        if (action === "lock") return ["bash", "-lc", "pidof hyprlock || hyprlock"]
        if (action === "sleep") return ["systemctl", "suspend"]
        if (action === "shutdown") return ["systemctl", "poweroff"]
        if (action === "reboot") return ["systemctl", "reboot"]
        return ["true"]
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: powerOpen
        onActivated: closePopup()
    }

    Process {
        id: actionProcess
        command: root.commandForAction(root.pendingAction)
    }

    Text {
        id: powerIcon

        anchors.centerIn: parent
        text: "󰐥"
        color: Style.barIcon
        font.family: Style.monoFont
        font.pixelSize: 16

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglePopup()
        }
    }

    PanelWindow {
        screen: root.shellScreen
        visible: root.powerOpen
        implicitWidth: 190
        implicitHeight: 190
        anchors { top: true; right: true }
        margins { top: 42; right: 12 }
        color: "transparent"

        WlrLayershell.namespace: "power-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: if (visible) powerPopup.forceActiveFocus()

        Rectangle {
            id: powerPopup

            anchors.fill: parent
            focus: root.powerOpen
            radius: Style.radius
            color: Style.popupBackground
            border.color: Style.border
            border.width: Style.borderWidth

            Keys.onEscapePressed: root.closePopup()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.padding
                spacing: 6

                Text {
                    text: "Power"
                    color: Style.foreground
                    font.family: Style.uiFont
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.inactiveBorder
                }

                Repeater {
                    model: [
                        { label: "Lock", icon: "󰌾", action: "lock" },
                        { label: "Sleep", icon: "󰒲", action: "sleep" },
                        { label: "Shut down", icon: "󰐥", action: "shutdown" },
                        { label: "Reboot", icon: "󰜉", action: "reboot" }
                    ]

                    Rectangle {
                        id: actionButton

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: Style.radius
                        color: actionMouse.containsMouse || actionMouse.pressed ? Style.selected : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: actionButton.modelData.icon
                                color: actionButton.modelData.action === "shutdown" ? Style.critical : Style.foreground
                                font.family: Style.monoFont
                                font.pixelSize: 15
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: actionButton.modelData.label
                                color: actionButton.modelData.action === "shutdown" ? Style.critical : Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: actionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runAction(actionButton.modelData.action)
                        }
                    }
                }
            }
        }
    }
}
