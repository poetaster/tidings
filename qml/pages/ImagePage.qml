import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root
    objectName: "ImagePage"

    property string url

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        /*
        PullDownMenu {
            MenuItem {
                text: qsTr("Save to gallery")
                onClicked: {
                    console.log("Save to gallery");
                }
            }
        }
        */

        Image {
            id: image
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: root.url
        }
    }

}
