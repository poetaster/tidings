import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property int sourceId
    property alias name: inputName.text
    property alias url: inputUrl.text
    property alias color: swatch.color
    property bool editOnly
    property Item item

    canAccept: inputName.text !== ""
               && inputUrl.text !== ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: childrenRect.height

        PullDownMenu {
            visible: dialog.item !== null

            MenuItem {
                text: qsTr("Remove")

                onClicked: {
                    dialog.item.remove();
                    dialog.close();
                }
            }
        }

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
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
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

            Item {
                width: 1
                height: Theme.paddingSizeLarge
            }

            Button {
                visible: editOnly
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Forget about read items"
                onClicked: {
                    sourcesModel.forgetSourceRead(url);
                }
            }
        }//Column
    }//Flickable


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
