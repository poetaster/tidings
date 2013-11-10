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
    }

    SilicaListView {
        id: listview

        anchors.fill: parent
        //spacing: Theme.paddingSmall

        model: newsBlendModel

        header: PageHeader {
            title: "Tidings"
        }

        PullDownMenu {
            MenuItem {
                text: "About Tidings"

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                }
            }

            MenuItem {
                text: "Refresh"

                onClicked: {
                    newsBlendModel.refresh();
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: "Back to top"

                onClicked: {
                    listview.scrollToTop();
                }
            }
        }

        delegate: ListItem {
            width: listview.width
            contentHeight: Theme.itemSizeExtraLarge
            clip: true

            Image {
                id: picture
                visible: status === Image.Ready
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                width: 32
                height: 32
                fillMode: Image.PreserveAspectCrop
                smooth: true
                clip: true
                source: thumbnail
            }

            Label {
                id: feedLabel
                anchors.left: picture.visible ? picture.right : parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: name + " (" + Format.formatDate(date, Formatter.DurationElapsed) + ")"
            }

            Separator {
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.primaryColor
            }

            Label {
                id: headerLabel
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                text: title
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
            text: "No tidings is glad tidings?\n\nPlease add some sources. →"
        }

        ScrollDecorator { }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: listview.count === 0 & sourcesModel.count > 0
        size: BusyIndicatorSize.Large

    }
}
