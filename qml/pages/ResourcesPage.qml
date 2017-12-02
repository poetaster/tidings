import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "ResourcesPage"

    property variant resources
    property variant _images: resources.images

    property bool _activated

    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active)
        {
            _activated = true;
        }
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        cellWidth: width > height ? width / 2 : width
        cellHeight: Theme.itemSizeLarge

        model: _images

        header: PageHeader {
            title: qsTr("Resources")
        }

        delegate: MediaItem {
            width: gridView.cellWidth
            contentHeight: gridView.cellHeight
            url: page._activated ? modelData : ""
            mimeType: "image/x-unknown"
            length: -1
        }

        ScrollDecorator { }
    }

    /*
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
                    url: page._activated ? modelData : ""
                    mimeType: "image/x-unknown"
                    length: -1
                }
            }//Repeater
        }

        ScrollDecorator { }
    }
    */
}
