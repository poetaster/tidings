import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

Page {
    id: root
    objectName: "WebPage"

    property string title
    property string url

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    onStatusChanged: {
        console.log("status changed -> " + status + " / " + PageStatus.Active);
        console.log("urlLoader.source = " + urlLoader.source);
        if (status === PageStatus.Active && urlLoader.source == "")
        {
            urlLoader.source = root.url;
        }
    }

    HtmlFilter {
        id: htmlFilter
        baseUrl: urlLoader.source
        imageProxy: configLoadImages.booleanValue ? "" :  imagePlaceholder
        html: urlLoader.data
    }

    UrlLoader {
        id: urlLoader
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight

        PullDownMenu {
            MenuItem {
                text: "Toggle Source Code"

                onClicked: {
                    body.showSource = ! body.showSource;
                }
            }

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

            LoadImagesButton {
                visible: htmlFilter.imageProxy !== "" &&
                         htmlFilter.images.length > 0
                width: parent.width

                onClicked: {
                    htmlFilter.imageProxy = "";
                }
            }

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
                text: htmlFilter.htmlFiltered

                onLinkActivated: {
                    var props = {
                        "url": link
                    }
                    pageStack.push(Qt.resolvedUrl("ExternalLinkDialog.qml"),
                                                  props);
                }

            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            ListItem {
                id: resourcesItem
                property var _images: htmlFilter.images

                visible: _images.length > 0

                width: column.width
                contentHeight: Theme.itemSizeLarge

                Image {
                    id: arrowIcon
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    source: "image://theme/icon-m-right"
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: arrowIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    text: qsTr("Resources")
                }

                onClicked: {
                    var props = {
                        "images": _images
                    }
                    pageStack.push(Qt.resolvedUrl("ResourcesPage.qml"), props);
                }
            }

        }


        ScrollDecorator { }
    }

    BusyIndicator {
        running: urlLoader.loading || htmlFilter.busy
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}
