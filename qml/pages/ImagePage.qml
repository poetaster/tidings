import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root
    objectName: "ImagePage"

    property string url
    property string name: "unnamed.dat"

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: qsTr("Save to gallery")
                onClicked: {
                    downloader.downloadToGallery(url, name);
                }
            }
        }

        Image {
            id: image
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            source: root.url
            asynchronous: true

            BusyIndicator {
                running: parent.status === Image.Loading
                anchors.centerIn: parent
                size: BusyIndicatorSize.Large
            }
        }
    }


}
