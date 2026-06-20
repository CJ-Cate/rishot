import QtQuick
import "Singletons"

Rectangle {
    id: toast

    property string text: ""
    property bool error: false
    property bool busy: false

    readonly property color accent: toast.error ? Theme.vermilion
        : (toast.busy ? Theme.idle : "#5bbf73")

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 34
    radius: 8
    color: Theme.panelBg
    border.color: Theme.panelBorder
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 9

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: toast.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: toast.text
            color: Theme.idle
            font.family: Theme.monoFamily
            font.pixelSize: 13
        }
    }
}
