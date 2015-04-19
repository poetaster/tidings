import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {

    property string url

    allowedOrientations: Orientation.All

    DialogHeader {
        title: qsTr("Open in browser")
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.highlightColor
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        text: url
    }

    onAccepted: {
        Qt.openUrlExternally(url);
    }

}
