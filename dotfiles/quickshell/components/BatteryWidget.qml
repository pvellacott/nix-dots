import QtQuick
import qs.services
import "Style.js" as Style

Text {
    id: root

    property real textSize: 13

    visible: BatteryService.available
    text: batteryIcon() + " " + BatteryService.percent + "%"
    color: Style.barIcon
    font.family: Style.monoFont
    font.pixelSize: textSize

    function batteryIcon() {
        if (BatteryService.charging) return "󰂄"
        if (BatteryService.percent <= 10) return "󰁺"
        if (BatteryService.percent <= 25) return "󰁻"
        if (BatteryService.percent <= 50) return "󰁾"
        if (BatteryService.percent <= 75) return "󰂀"
        return "󰁹"
    }
}
