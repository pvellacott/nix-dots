import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "Style.js" as Style

Item {
    property var notificationRefs: ({})

    ListModel { id: notificationModel }

    function notificationDuration(urgency, expireTimeout) {
        if (urgency === NotificationUrgency.Critical) return 0

        var requested = Number(expireTimeout || 0)
        if (!isFinite(requested) || requested <= 0)
            requested = urgency === NotificationUrgency.Low ? 5000 : 8000

        return Math.min(30000, Math.max(urgency === NotificationUrgency.Low ? 5000 : 8000, Math.round(requested)))
    }

    function notificationImageSource(value) {
        var source = String(value || "")
        if (source.length === 0) return ""
        if (source.indexOf("file://") === 0 || source.indexOf("image://") === 0) return source
        if (source.charAt(0) === "/") return "file://" + source
        return Quickshell.iconPath(source, true)
    }

    function notificationSnapshot(notification) {
        return {
            notificationId: notification.id || 0,
            app: String(notification.appName || ""),
            appIcon: String(notification.appIcon || ""),
            summary: String(notification.summary || ""),
            body: String(notification.body || "").replace(/<img[^>]*>/gi, ""),
            image: String(notification.image || ""),
            urgency: notification.urgency,
            expireTimeout: Number(notification.expireTimeout || 0)
        }
    }

    function addNotification(notification) {
        notification.tracked = true

        var snapshot = notificationSnapshot(notification)
        notificationRefs[snapshot.notificationId] = notification
        notification.closed.connect(function() {
            if (notificationRefs[snapshot.notificationId] === notification)
                delete notificationRefs[snapshot.notificationId]
        })

        for (var i = notificationModel.count - 1; i >= 0; i--) {
            if (notificationModel.get(i).notificationId === snapshot.notificationId)
                notificationModel.remove(i)
        }

        notificationModel.insert(0, snapshot)
    }

    function dismissNotification(index, expired) {
        if (index < 0 || index >= notificationModel.count) return

        var entry = notificationModel.get(index)
        var ref = notificationRefs[entry.notificationId]
        notificationModel.remove(index)

        if (!ref) return
        delete notificationRefs[entry.notificationId]

        try {
            if (expired && typeof ref.expire === "function")
                ref.expire()
            else
                ref.dismiss()
        } catch (e) {}
    }

    function activateNotification(index) {
        if (index < 0 || index >= notificationModel.count) return

        var entry = notificationModel.get(index)
        var ref = notificationRefs[entry.notificationId]

        try {
            if (ref && ref.actions) {
                for (var i = 0; i < ref.actions.length; i++) {
                    if (ref.actions[i] && ref.actions[i].identifier === "default") {
                        ref.actions[i].invoke()
                        break
                    }
                }
            }
        } catch (e) {}

        dismissNotification(index, false)
    }

    NotificationServer {
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: function(notification) {
            addNotification(notification)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: notificationModel.count > 0
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.namespace: "notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            mask: Region { item: notificationColumn }

            ColumnLayout {
                id: notificationColumn

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 44
                anchors.rightMargin: 12
                spacing: 8

                Repeater {
                    model: notificationModel

                    Item {
                        id: notificationSlot

                        required property int index
                        required property int notificationId
                        required property string app
                        required property string appIcon
                        required property string summary
                        required property string body
                        required property string image
                        required property int urgency
                        required property double expireTimeout

                        Layout.preferredWidth: notificationCard.implicitWidth
                        Layout.preferredHeight: notificationCard.implicitHeight
                        Layout.alignment: Qt.AlignRight

                        readonly property int lifetime: notificationDuration(urgency, expireTimeout)

                        Timer {
                            interval: notificationSlot.lifetime
                            running: notificationSlot.lifetime > 0 && !notificationHover.hovered
                            repeat: false
                            onTriggered: dismissNotification(notificationSlot.index, true)
                        }

                        Rectangle {
                            id: notificationCard

                            readonly property string iconSource: notificationImageSource(notificationSlot.image.length > 0 ? notificationSlot.image : notificationSlot.appIcon)
                            readonly property color accent: notificationSlot.urgency === NotificationUrgency.Critical ? Style.critical : Style.border

                            implicitWidth: 420
                            implicitHeight: Math.max(110, notificationContent.implicitHeight + 20)
                            radius: Style.radius
                            color: Style.popupBackground
                            border.color: accent
                            border.width: Style.borderWidth
                            clip: true

                            HoverHandler { id: notificationHover }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton)
                                        dismissNotification(notificationSlot.index, false)
                                    else
                                        activateNotification(notificationSlot.index)
                                }
                            }

                            RowLayout {
                                id: notificationContent

                                anchors.fill: parent
                                anchors.margins: Style.padding
                                spacing: Style.spacing

                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignTop

                                    Image {
                                        id: notificationIcon
                                        anchors.fill: parent
                                        source: notificationCard.iconSource
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        smooth: true
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: notificationIcon.status !== Image.Ready
                                        text: "󰂚"
                                        color: Style.foreground
                                        font.family: Style.monoFont
                                        font.pixelSize: 24
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.rightMargin: 18
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: notificationSlot.summary.length > 0 ? notificationSlot.summary : notificationSlot.app
                                        color: Style.foreground
                                        font.family: Style.uiFont
                                        font.pixelSize: 12
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: notificationSlot.body.length > 0
                                        text: notificationSlot.body.replace(/\r\n|\r|\n/g, "<br/>")
                                        textFormat: Text.StyledText
                                        color: Style.mutedForeground
                                        font.family: Style.uiFont
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 3
                                    }
                                }
                            }

                            Text {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 6
                                anchors.rightMargin: 8
                                visible: notificationHover.hovered
                                text: "x"
                                color: closeNotificationArea.containsMouse ? Style.foreground : Style.dimForeground
                                font.pixelSize: 14

                                MouseArea {
                                    id: closeNotificationArea
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dismissNotification(notificationSlot.index, false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
