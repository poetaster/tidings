import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "ViewPage"

    property int index: 0
    property string feedName: newsBlendModel.get(index).name
    property string title: newsBlendModel.get(index).title
    property string preview: newsBlendModel.get(index).description
    property string url: newsBlendModel.get(index).link
    property string color: newsBlendModel.get(index).color
    property string date: newsBlendModel.get(index).date
    property bool read: newsBlendModel.get(index).read

    property int _previousOfFeed: newsBlendModel.previousOfFeed(index)
    property int _nextOfFeed: newsBlendModel.nextOfFeed(index)

    // style for rich text
    property string _style: "<style>a:link { color:" + Theme.highlightColor + "}</style>"

    function previousItem() {
        var props = {
            "index": index - 1
        };
        pageStack.replace("ViewPage.qml", props);
    }

    function nextItem() {
        var props = {
            "index": index + 1
        };
        pageStack.replace("ViewPage.qml", props);
    }

    function goToItem(idx)
    {
        var props = {
            "index": idx
        };
        pageStack.replace("ViewPage.qml", props);
    }

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    Component.onCompleted: {
        navigationState.openedItem(index);
        if (! read) {
            newsBlendModel.setRead(index, true);
        }
    }

    Connections {
        target: coverAdaptor

        onPreviousItem: {
            previousItem();
        }

        onNextItem: {
            nextItem();
        }
    }

    Rectangle {
        width: 2
        height: parent.height
        color: page.color
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                enabled: _previousOfFeed !== -1
                text: feedName

                onClicked: {
                    goToItem(_previousOfFeed);
                }
            }
            MenuItem {
                enabled: index > 0
                text: enabled ? qsTr("Previous")
                              : qsTr("Already at the beginning")

                onClicked: {
                    goToItem(index - 1)
                }
            }
        }

        PushUpMenu {
            MenuItem {
                enabled: index < newsBlendModel.count - 1
                text: enabled ? qsTr("Next")
                              : qsTr("Already at the end")

                onClicked: {
                    goToItem(index + 1)
                }
            }
            MenuItem {
                enabled: _nextOfFeed !== -1
                text: feedName

                onClicked: {
                    goToItem(_nextOfFeed);
                }
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            height: childrenRect.height

            PageHeader {
                id: pageHeader
                title: page.feedName
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                text: page.title
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: Format.formatDate(page.date, Formatter.Timepoint)
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Label {
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                text: _style + page.preview
                textFormat: Text.RichText
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Button {
                visible: page.url !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Full view")

                onClicked: {
                    var props = {
                        "url": page.url
                    };
                    pageStack.push("WebPage.qml", props);
                }
            }
        }

        ScrollDecorator { }
    }
}
