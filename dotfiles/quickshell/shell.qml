import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "components"
import "components/Style.js" as Style
import qs.services

ShellRoot {
    id: root

    readonly property real textSize: SettingsService.textSize
    property int targetWorkspace: 1
    property bool wallpaperAvailable: false

    function switchWorkspace(workspace) {
        targetWorkspace = workspace
        if (!switchWorkspaceProcess.running) switchWorkspaceProcess.running = true
    }

    Process {
        id: switchWorkspaceProcess
        command: ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + String(targetWorkspace) + " })"]
    }

    Process {
        command: ["test", "-r", "/home/smoo/Pictures/Wallpapers/snow.png"]
        running: true
        onExited: exitCode => wallpaperAvailable = exitCode === 0
    }

    Notifications {}

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
                            color: parent.active ? Style.barIcon : Style.barMuted
                            font.family: Style.monoFont
                            font.pixelSize: root.textSize
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
                font.pixelSize: root.textSize

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
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12
                spacing: 12

                NetworkWidget {
                    id: networkWidget
                    shellScreen: modelData
                    iconSize: root.textSize + 2
                    onOpened: {
                        audioWidget.closePopup()
                        displayWidget.closePopup()
                        bluetoothWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                BluetoothWidget {
                    id: bluetoothWidget
                    shellScreen: modelData
                    iconSize: root.textSize + 2
                    onOpened: {
                        audioWidget.closePopup()
                        displayWidget.closePopup()
                        networkWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                AudioWidget {
                    id: audioWidget
                    shellScreen: modelData
                    iconSize: root.textSize + 2
                    onOpened: {
                        displayWidget.closePopup()
                        networkWidget.closePopup()
                        bluetoothWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                DisplayWidget {
                    id: displayWidget
                    shellScreen: modelData
                    iconSize: root.textSize + 2
                    onOpened: {
                        audioWidget.closePopup()
                        networkWidget.closePopup()
                        bluetoothWidget.closePopup()
                        powerWidget.closePopup()
                    }
                }

                BatteryWidget {
                    anchors.verticalCenter: parent.verticalCenter
                    textSize: root.textSize
                }

                PowerWidget {
                    id: powerWidget
                    shellScreen: modelData
                    iconSize: root.textSize + 2
                    onOpened: {
                        audioWidget.closePopup()
                        displayWidget.closePopup()
                        networkWidget.closePopup()
                        bluetoothWidget.closePopup()
                    }
                }
            }
        }
    }
}
