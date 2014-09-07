import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("Settings")
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Show preview images")
                description: qsTr("Hiding the preview images saves network traffic. This switch does not affect embedded images in the item view.")
                automaticCheck: false
                checked: configShowPreviewImages.booleanValue

                onClicked: {
                    configShowPreviewImages.value =
                            configShowPreviewImages.booleanValue ? "0" : "1";
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Tinted items")
                description: qsTr("If enabled, items have their background tinted in their tag color.")
                automaticCheck: false
                checked: configTintedItems.booleanValue

                onClicked: {
                    configTintedItems.value =
                            configTintedItems.booleanValue ? "0" : "1";
                }
            }

        }//Column

    }

}

