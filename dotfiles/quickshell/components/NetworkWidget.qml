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

    property bool networkOpen: false
    property string connectionType: "none"
    property string connectionName: "Disconnected"
    property string pendingSsid: ""
    property string passphrase: ""
    property string statusMessage: ""
    property bool scanning: false
    property bool networkEnabled: true
    property string networkTarget: "on"

    signal opened()

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: networkOpen
        onActivated: closePopup()
    }

    width: networkIcon.implicitWidth
    height: networkIcon.implicitHeight

    function icon() {
        if (connectionType === "ethernet") return "󰈀"
        if (connectionType === "wifi") return "󰖩"
        return "󰖪"
    }

    function refresh() {
        readNetworking.running = true
        readStatus.running = true
        if (!networkEnabled) {
            scanning = false
            networkModel.clear()
            return
        }

        scanning = true
        scanWifi.running = true
    }

    function closePopup() {
        networkOpen = false
        pendingSsid = ""
        passphrase = ""
        statusMessage = ""
    }

    function togglePopup() {
        if (networkOpen) {
            closePopup()
            return
        }

        networkOpen = true
        opened()
        refresh()
    }

    function connectTo(ssid, security, active) {
        if (!networkEnabled) {
            statusMessage = "Turn internet on before connecting"
            return
        }

        if (active) {
            pendingSsid = ""
            passphrase = ""
            statusMessage = "Already connected to " + ssid
            return
        }

        pendingSsid = ssid
        passphrase = ""
        statusMessage = ""

        if (String(security || "").length > 0) {
            passwordField.forceActiveFocus()
        } else {
            connectWifi.running = true
        }
    }

    function toggleNetwork() {
        if (toggleNetworking.running) return
        networkTarget = networkEnabled ? "off" : "on"
        statusMessage = ""
        if (networkTarget === "off") {
            scanning = false
            pendingSsid = ""
            passphrase = ""
            networkModel.clear()
        }
        toggleNetworking.running = true
    }

    ListModel { id: networkModel }

    Process {
        id: readNetworking
        command: ["nmcli", "networking"]
        stdout: StdioCollector {
            onStreamFinished: networkEnabled = String(text).trim() === "enabled"
        }
    }

    Process {
        id: readStatus
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = String(text).trim().split("\n")
                var nextType = "none"
                var nextName = "Disconnected"

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 3 || parts[1].indexOf("connected") !== 0) continue

                    if (parts[0] === "ethernet") {
                        nextType = "ethernet"
                        nextName = parts.slice(2).join(":") || "Ethernet"
                        break
                    }

                    if (parts[0] === "wifi" && nextType !== "ethernet") {
                        nextType = "wifi"
                        nextName = parts.slice(2).join(":") || "Wi-Fi"
                    }
                }

                connectionType = nextType
                connectionName = nextName
            }
        }
    }

    Process {
        id: scanWifi
        command: ["nmcli", "-t", "--escape", "no", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                scanning = false
                networkModel.clear()

                var seen = ({})
                var lines = String(text).trim().split("\n")

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 4) continue

                    var ssid = parts[1]
                    if (!ssid) continue

                    var active = parts[0] === "yes"
                    var signal = Number(parts[2]) || 0
                    var security = parts.slice(3).join(":")

                    if (seen[ssid] !== undefined) {
                        var index = seen[ssid]
                        var existing = networkModel.get(index)
                        if (active || signal > existing.signal) {
                            networkModel.set(index, {
                                active: active,
                                ssid: ssid,
                                signal: signal,
                                security: security
                            })
                        }
                        continue
                    }

                    seen[ssid] = networkModel.count
                    networkModel.append({
                        active: active,
                        ssid: ssid,
                        signal: signal,
                        security: security
                    })
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                scanning = false
                statusMessage = String(text).trim()
            }
        }
    }

    Process {
        id: connectWifi
        command: passphrase.length > 0
            ? ["nmcli", "device", "wifi", "connect", pendingSsid, "password", passphrase]
            : ["nmcli", "device", "wifi", "connect", pendingSsid]
        stdout: StdioCollector {
            onStreamFinished: {
                statusMessage = String(text).trim()
                pendingSsid = ""
                passphrase = ""
                refresh()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: statusMessage = String(text).trim()
        }
    }

    Process {
        id: toggleNetworking
        command: ["nmcli", "networking", networkTarget]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = String(text).trim()
                if (output.length > 0) statusMessage = output
                networkEnabled = networkTarget === "on"
                refresh()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                statusMessage = String(text).trim()
                readNetworking.running = true
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            readNetworking.running = true
            readStatus.running = true
        }
    }

    Text {
        id: networkIcon
        anchors.centerIn: parent
        text: root.icon()
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
        visible: root.networkOpen
        implicitWidth: 360
        implicitHeight: 430
        anchors { top: true; right: true }
        margins { top: 42; right: 12 }
        color: "transparent"

        WlrLayershell.namespace: "network-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: if (visible) networkPopup.forceActiveFocus()

        Rectangle {
            id: networkPopup

            anchors.fill: parent
            focus: root.networkOpen
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
                        text: "Network"
                        color: Style.foreground
                        font.family: Style.uiFont
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.icon()
                        color: Style.border
                        font.family: Style.monoFont
                        font.pixelSize: 16
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: networkEnabled ? connectionName : "Internet disabled"
                    color: Style.mutedForeground
                    font.family: Style.uiFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.inactiveBorder
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Internet"
                        color: Style.foreground
                        font.family: Style.uiFont
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 24
                        radius: 12
                        color: toggleNetworking.running || networkMouse.pressed ? Style.selected : networkEnabled ? Style.enabled : Style.disabled
                        border.color: Style.border
                        border.width: Style.borderWidth

                        Text {
                            anchors.centerIn: parent
                            text: toggleNetworking.running ? "Working" : networkEnabled ? "Turn off" : "Turn on"
                            color: Style.foreground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: networkMouse
                            anchors.fill: parent
                            enabled: !toggleNetworking.running
                            onClicked: toggleNetwork()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 24
                        radius: 12
                        color: scanning ? Style.selected : Style.enabled
                        border.color: Style.border
                        border.width: Style.borderWidth
                        opacity: networkEnabled ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: scanning ? "Scanning" : "Rescan"
                            color: Style.foreground
                            font.family: Style.uiFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: networkEnabled && !scanning
                            onClicked: {
                                scanning = true
                                scanWifi.running = true
                            }
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: networkModel

                    delegate: Rectangle {
                        required property bool active
                        required property string ssid
                        required property int signal
                        required property string security

                        width: ListView.view.width
                        height: 34
                        radius: 6
                        color: active ? Style.selected : "transparent"
                        border.color: active ? Style.border : Style.inactiveBorder
                        border.width: Style.borderWidth

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                text: active ? "󰱒" : signal >= 70 ? "󰤨" : signal >= 40 ? "󰤢" : "󰤟"
                                color: active ? Style.foreground : Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: ssid
                                color: active ? Style.foreground : Style.mutedForeground
                                font.family: Style.uiFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                text: security.length > 0 ? "󰌾" : ""
                                color: Style.mutedForeground
                                font.family: Style.monoFont
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.connectTo(ssid, security, active)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: pendingSsid.length > 0
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Passphrase for " + pendingSsid
                        color: Style.foreground
                        font.family: Style.uiFont
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            text: passphrase
                            echoMode: TextInput.Password
                            placeholderText: "Password"
                            onTextChanged: passphrase = text
                            onAccepted: connectWifi.running = true
                        }

                        Rectangle {
                            Layout.preferredWidth: 76
                            Layout.preferredHeight: 30
                            radius: 8
                            color: Style.enabled
                            border.color: Style.border
                            border.width: Style.borderWidth

                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: Style.foreground
                                font.family: Style.uiFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: connectWifi.running = true
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: statusMessage.length > 0
                    text: statusMessage
                    color: Style.mutedForeground
                    font.family: Style.uiFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }
}
