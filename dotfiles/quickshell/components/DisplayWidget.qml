import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "Style.js" as Style

Item {
    id: root

    required property var shellScreen

    property bool displayOpen: false
    property real iconSize: 16

    signal opened()

    width: displayIcon.implicitWidth
    height: displayIcon.implicitHeight

    function closePopup() {
        displayOpen = false
    }

    function togglePopup() {
        displayOpen = !displayOpen
        if (displayOpen) {
            opened()
            DisplayService.refresh()
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: displayOpen
        onActivated: closePopup()
    }

    HyprlandFocusGrab {
        windows: [displayPopupWindow]
        active: root.displayOpen
        onCleared: root.closePopup()
    }

    Text {
        id: displayIcon

        anchors.centerIn: parent
        text: "󰍹"
        color: Style.barIcon
        font.family: Style.monoFont
        font.pixelSize: root.iconSize

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglePopup()
        }
    }

    PanelWindow {
        id: displayPopupWindow

        screen: root.shellScreen
        visible: root.displayOpen
        implicitWidth: 300
        implicitHeight: 170
        anchors { top: true; right: true }
        margins { top: 42; right: 8 }
        color: "transparent"

        WlrLayershell.namespace: "brightness-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: if (visible) displayPopup.forceActiveFocus()

        Rectangle {
            id: displayPopup

            anchors.fill: parent
            focus: root.displayOpen
            radius: Style.radius
            color: Style.popupBackground
            border.color: Style.border
            border.width: Style.borderWidth

            Keys.onEscapePressed: root.closePopup()

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
                            text: Math.round(DisplayService.brightness) + "%"
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
                        value: DisplayService.brightness
                        onMoved: DisplayService.setBrightness(value)
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
                            text: Math.round(SettingsService.textSize) + "px"
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
                                        Layout.preferredWidth: SettingsService.textSize === modelData ? 18 : 10
                                        Layout.preferredHeight: 3
                                        radius: 2
                                        color: SettingsService.textSize === modelData ? Style.border : Style.inactiveBorder
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData
                                        color: SettingsService.textSize === modelData ? Style.foreground : Style.mutedForeground
                                        font.family: Style.monoFont
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsService.setTextSize(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
