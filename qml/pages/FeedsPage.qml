import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    onStatusChanged: {
        if (status === PageStatus.Active && pageStack.depth === 1) {
            pageStack.pushAttached("SourcesPage.qml", {});
        }
    }

    Connections {
        target: navigationState

        onOpenedItem: {
            listview.positionViewAtIndex(index, ListView.Visible);
            coverAdaptor.hasPrevious = index > 0;
            coverAdaptor.hasNext = index < newsBlendModel.count - 1;

            coverAdaptor.feedName = newsBlendModel.get(index).name;
            coverAdaptor.title = newsBlendModel.get(index).title;
            coverAdaptor.page = (index + 1) + "/" +  newsBlendModel.count;
        }
    }

    Connections {
        target: coverAdaptor

        onFirstItem: {
            pageStack.pop(page, PageStackAction.Immediate);
            pageStack.push("ViewPage.qml");
        }

        onRefresh: {
            newsBlendModel.refresh();
        }

        onAbort: {
            newsBlendModel.abort();
        }
    }

    SilicaListView {
        id: listview

        anchors.fill: parent

        model: newsBlendModel

        header: PageHeader {
            title: qsTr("Tidings")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("About Tidings")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                }
            }

            MenuItem {
                text: newsBlendModel.busy ? qsTr("Abort refreshing")
                                          : qsTr("Refresh")

                onClicked: {
                    if (newsBlendModel.busy) {
                        newsBlendModel.abort();
                    } else {
                        newsBlendModel.refresh();
                    }
                }
            }
        }

        delegate: ListItem {
            visible: ! newsBlendModel.busy
            width: listview.width
            contentHeight: Theme.itemSizeExtraLarge
            clip: true

            Rectangle {
                width: 2
                height: parent.height
                color: model.color
            }

            Label {
                id: feedLabel
                anchors.left: parent.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: name + " (" + Format.formatDate(date, Formatter.DurationElapsed) + ")"
            }

            Separator {
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.primaryColor
            }

            Label {
                id: headerLabel
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                opacity: read ? 0.5 : 1
                text: title
            }

            Image {
                id: picture
                visible: status === Image.Ready
                anchors.right: parent.right
                width: height
                height: parent.height
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectCrop
                smooth: true
                opacity: read ? 0.5 : 1
                clip: true
                source: thumbnail
            }

            Image {
                visible: model.enclosuresAmount && enclosuresAmount > 0
                anchors.top: parent.top
                anchors.right: parent.right
                source: "image://theme/icon-s-attach"
            }

            onClicked: {
                var props = {
                    "index": index
                };
                pageStack.push("ViewPage.qml", props);
            }
        }

        section.property: "sectionDate"
        section.delegate: SectionHeader {
            text: section
        }

        ViewPlaceholder {
            enabled: sourcesModel.count === 0
            text: qsTr("No tidings is glad tidings?\n\nPlease add some sources. →")
        }

        ViewPlaceholder {
            enabled: sourcesModel.count > 0 &&
                     ! newsBlendModel.busy &&
                     newsBlendModel.count === 0
            text: qsTr("Pull down to refresh.")
        }

        ScrollDecorator { }
    }

    FancyScroller {
        flickable: listview
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: newsBlendModel.busy
        size: BusyIndicatorSize.Large

    }

    Label {
        visible: newsBlendModel.busy
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.paddingMedium
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.secondaryColor
        truncationMode: TruncationMode.Fade
        text: newsBlendModel.currentlyLoading
    }
}
