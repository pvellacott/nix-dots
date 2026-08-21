import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Style.js" as Style

Item {
    id: root

    required property var shellScreen

    property bool audioOpen: false
    property real iconSize: 16
    property real maxPopupHeight: 700

    readonly property var sink: Pipewire.defaultAudioSink

    signal opened()

    width: audioIcon.implicitWidth
    height: audioIcon.implicitHeight

    function audioNodeLabel(node) {
        if (!node) return "Unavailable"
        return node.nickname || node.description || node.name || "Unknown device"
    }

    function closePopup() {
        audioOpen = false
    }

    function togglePopup() {
        audioOpen = !audioOpen
        if (audioOpen) opened()
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: audioOpen
        onActivated: closePopup()
    }

    HyprlandFocusGrab {
        windows: [audioPopupWindow]
        active: root.audioOpen
        onCleared: root.closePopup()
    }

    Text {
        id: audioIcon

        anchors.centerIn: parent
        text: "󰋋"
        color: Style.barIcon
        font.family: Style.monoFont
        font.pixelSize: root.iconSize

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                } else {
                    root.togglePopup()
                }
            }
        }
    }

    PanelWindow {
        id: audioPopupWindow

        screen: root.shellScreen
        visible: root.audioOpen
        implicitWidth: 360
        implicitHeight: Math.min(root.maxPopupHeight, root.shellScreen.height - 54, Math.max(280, audioContent.implicitHeight + Style.padding * 2 + 2))
        anchors { top: true; right: true }
        margins { top: 42; right: 12 }
        color: "transparent"

        WlrLayershell.namespace: "volume-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: if (visible) audioPopup.forceActiveFocus()

        Rectangle {
            id: audioPopup

            anchors.fill: parent
            focus: root.audioOpen
            radius: Style.radius
            color: Style.popupBackground
            border.color: Style.border
            border.width: Style.borderWidth

            Keys.onEscapePressed: root.closePopup()

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var source: Pipewire.defaultAudioSource
            readonly property real sinkVolume: sink && sink.audio ? sink.audio.volume : 0
            readonly property real sourceVolume: source && source.audio ? source.audio.volume : 0

            PwObjectTracker { objects: [audioPopup.sink, audioPopup.source].filter(function(node) { return node !== null }) }

            ScrollView {
                id: audioScroll

                anchors.fill: parent
                anchors.margins: Style.padding
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: audioContent

                    width: audioScroll.availableWidth
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
                            text: audioPopup.sink && audioPopup.sink.audio && audioPopup.sink.audio.muted ? "Muted" : Math.round(audioPopup.sinkVolume * 100) + "%"
                            color: Style.mutedForeground
                            font.family: Style.monoFont
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.audioNodeLabel(audioPopup.sink)
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
                            color: audioPopup.sink && audioPopup.sink.audio && audioPopup.sink.audio.muted ? Style.disabled : Style.enabled
                            border.color: Style.border
                            border.width: Style.borderWidth

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: audioPopup.sink && audioPopup.sink.audio && audioPopup.sink.audio.muted ? "󰝟" : "󰋋"
                                    color: Style.foreground
                                    font.family: Style.monoFont
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: audioPopup.sink && audioPopup.sink.audio && audioPopup.sink.audio.muted ? "Unmute" : "Mute"
                                    color: Style.foreground
                                    font.family: Style.uiFont
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (audioPopup.sink && audioPopup.sink.audio) audioPopup.sink.audio.muted = !audioPopup.sink.audio.muted
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1
                            value: audioPopup.sinkVolume
                            enabled: audioPopup.sink && audioPopup.sink.audio
                            onMoved: if (audioPopup.sink && audioPopup.sink.audio) audioPopup.sink.audio.volume = value
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
                                readonly property bool isSelected: audioPopup.sink && node && audioPopup.sink.id === node.id

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
                                    text: root.audioNodeLabel(node)
                                    color: isSelected ? Style.foreground : Style.mutedForeground
                                    font.family: Style.uiFont
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
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
                            text: audioPopup.source && audioPopup.source.audio && audioPopup.source.audio.muted ? "Muted" : Math.round(audioPopup.sourceVolume * 100) + "%"
                            color: Style.mutedForeground
                            font.family: Style.monoFont
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.audioNodeLabel(audioPopup.source)
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
                            color: audioPopup.source && audioPopup.source.audio && audioPopup.source.audio.muted ? Style.disabled : Style.enabled
                            border.color: Style.border
                            border.width: Style.borderWidth

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: audioPopup.source && audioPopup.source.audio && audioPopup.source.audio.muted ? "󰍭" : "󰍬"
                                    color: Style.foreground
                                    font.family: Style.monoFont
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: audioPopup.source && audioPopup.source.audio && audioPopup.source.audio.muted ? "Unmute" : "Mute"
                                    color: Style.foreground
                                    font.family: Style.uiFont
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (audioPopup.source && audioPopup.source.audio) audioPopup.source.audio.muted = !audioPopup.source.audio.muted
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1
                            value: audioPopup.sourceVolume
                            enabled: audioPopup.source && audioPopup.source.audio
                            onMoved: if (audioPopup.source && audioPopup.source.audio) audioPopup.source.audio.volume = value
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
                                readonly property bool isSelected: audioPopup.source && node && audioPopup.source.id === node.id

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
                                    text: root.audioNodeLabel(node)
                                    color: isSelected ? Style.foreground : Style.mutedForeground
                                    font.family: Style.uiFont
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
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
}
