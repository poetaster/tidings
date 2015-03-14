import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    objectName: "ResourcesPage"

    property variant resources
    property variant _images: resources.images

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("Resources")
            }

            SectionHeader {
                visible: imagesRepeater.count > 0
                text: qsTr("Embedded images")
            }

            Repeater {
                id: imagesRepeater
                model: _images

                delegate: MediaItem {
                    width: column.width
                    url: modelData
                    mimeType: "image/x-unknown"
                    length: -1
                }
            }//Repeater
        }

        ScrollDecorator { }
    }
}
