import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    width: parent.width
    height: Theme.itemSizeSmall
    clip: true
    visible: box.y > -height

    function show(message)
    {
        label.text = message;
        box.y = 0;
        notificationTimer.restart();
    }

    Rectangle {
        id: box
        y: -width
        width: parent.width
        height: parent.height
        color: Theme.highlightBackgroundColor
        clip: true

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        Image {
            id: icon
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.paddingSmall
            width: height

            source: "image://theme/icon-lock-warning"
        }

        Label {
            id: label
            anchors.top: parent.top
            anchors.left: icon.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.paddingSmall

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.family: Theme.fontFamilyHeading
            font.pixelSize: Theme.fontSizeSmall
            color: "#000000"
            opacity: 0.7
        }
    }

    Timer {
        id: notificationTimer
        interval: 3000

        onTriggered: {
            box.y = -height;
        }
    }

    onClicked: {
        box.y = -height;
        notificationTimer.stop();
    }
}
