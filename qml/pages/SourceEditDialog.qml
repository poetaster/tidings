import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {

    property int sourceId
    property alias name: inputName.text
    property alias url: inputUrl.text
    property alias color: swatch.color
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
            text: qsTr("Name")
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

        BackgroundItem {
            id: colorPicker
            height: Theme.itemSizeSmall

            Rectangle {
                id: swatch
                width: height
                height: parent.height
                radius: 3
                color: "#e60003"
            }

            Label {
                anchors.left: swatch.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.paddingMedium
                color: parent.down ? Theme.highlightColor : Theme.primaryColor
                text: qsTr("Color tag")
            }

            onClicked: {
                var dlg = pageStack.push("Sailfish.Silica.ColorPickerDialog");

                function f() {
                    swatch.color = dlg.color;
                }

                dlg.accepted.connect(f);
            }
        }
    }

    onAccepted: {
        if (editOnly) {
            sourcesModel.changeSource(sourceId,
                                      inputName.text,
                                      inputUrl.text,
                                      "" + swatch.color);
        } else {
            sourcesModel.addSource(inputName.text,
                                   inputUrl.text,
                                   "" + swatch.color);
        }
    }

}
