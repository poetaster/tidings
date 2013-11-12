import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {

    property int sourceId
    property alias name: inputName.text
    property alias url: inputUrl.text
    property bool editOnly

    canAccept: inputName.text !== ""
               && inputUrl.text !== ""

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.paddingMedium
        anchors.rightMargin: Theme.paddingMedium
        spacing: Theme.paddingSmall

        DialogHeader {
            title: qsTr("Save")
        }

        Label {
            text: "Name"
        }

        TextField {
            id: inputName
            width: parent.width
            placeholderText: qsTr("Enter name")
        }

        Label {
            text: qsTr("Source Address")
        }

        TextField {
            id: inputUrl
            width: parent.width
            placeholderText: qsTr("Enter URL")
        }
    }

    onAccepted: {
        if (editOnly) {
            sourcesModel.changeSource(sourceId,
                                      inputName.text,
                                      inputUrl.text);
        } else {
            sourcesModel.addSource(inputName.text,
                                   inputUrl.text);
        }
    }

}
