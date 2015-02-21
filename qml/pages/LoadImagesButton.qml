import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    contentHeight: Theme.itemSizeLarge
    highlighted: true

    Label {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.paddingLarge
        font.underline: true
        text: qsTr("Load images")
    }
}
