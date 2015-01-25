import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

Page {
    id: root
    objectName: "WebPage"

    property string title
    property string url

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    UrlLoader {
        id: urlLoader
        source: root.status === PageStatus.Active ? root.url : ""

        onDataChanged: {
            if (source !== "")
            {
                body.text = htmlFilter.filter(data);
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight

        PullDownMenu {
            MenuItem {
                text: qsTr("Open in browser")

                onClicked: {
                    Qt.openUrlExternally(root.url);
                }
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: root.title
            }

            RescalingRichText {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                color: Theme.primaryColor
                fontSize: Theme.fontSizeSmall * (configFontScale.value / 100.0)

                onLinkActivated: {
                    var props = {
                        "url": link
                    }
                    pageStack.push(Qt.resolvedUrl("ExternalLinkDialog.qml"),
                                                  props);
                }

            }
        }


        ScrollDecorator { }
    }

    BusyIndicator {
        running: urlLoader.loading
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}
