import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "FeedsPage"

    function replaceEntities(text)
    {
        return text.replace(/&apos;/g, "'")
                   .replace(/&quot;/g, "\"")
                   .replace(/&#38;/g, "&")
                   .replace(/&Auml;/g, "Ä")
                   .replace(/&auml;/g, "ä")
                   .replace(/&Ouml;/g, "Ö")
                   .replace(/&ouml;/g, "ö")
                   .replace(/&Uuml;/g, "Ü")
                   .replace(/&uuml;/g, "ü")
                   .replace(/&amp;/g, "&");
    }

    function positionAtFirst(feedUrl)
    {
        var idx = newsBlendModel.firstOfFeed(feedUrl);
        if (idx !== -1)
        {
            listview.positionViewAtIndex(idx,
                                         ListView.Beginning);
        }
    }

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    Timer {
        id: initTimer
        interval: 500
        running: true

        onTriggered: {
            newsBlendModel.loadPersistedItems();
        }
    }

    Connections {
        target: navigationState

        onOpenedItem: {
            listview.positionViewAtIndex(index, ListView.Visible);
            coverAdaptor.hasPrevious = index > 0;
            coverAdaptor.hasNext = index < newsBlendModel.count - 1;

            coverAdaptor.feedName = newsBlendModel.getAttribute(index, "name");
            coverAdaptor.title = newsBlendModel.getAttribute(index, "title");
            coverAdaptor.thumbnail = newsBlendModel.getAttribute(index, "thumbnail");

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
            newsBlendModel.refreshAll();
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
                //enabled: ! newsBlendModel.busy
                text: qsTr("Sort by: %1").arg(newsBlendModel.feedSorter.name)

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SortSelectorPage.qml"));
                }
            }
        }

        delegate: ListItem {
            id: feedItem

            property variant data: model

            //opacity: newsBlendModel.busy ? 0.2 : 1
            //enabled: ! newsBlendModel.busy

            width: listview.width
            contentHeight: Theme.itemSizeExtraLarge
            clip: true

            Rectangle {
                width: 2
                height: parent.height
                color: model.color
            }

            Image {
                id: shelveIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
                visible: model.shelved
                source: "image://theme/icon-s-favorite"
            }

            Label {
                id: feedLabel
                anchors.left: shelveIcon.visible ? shelveIcon.right : parent.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.leftMargin: shelveIcon.visible ? Theme.paddingSmall : Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium
                color: feedItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: (minuteTimer.tick ? "" : "") +
                      model.name + " (" +
                      Format.formatDate(model.date, Formatter.DurationElapsed) +
                      ")"
            }

            Separator {
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: feedItem.highlighted ? Theme.primaryColor : Theme.highlightColor
            }

            Label {
                id: headerLabel
                anchors.top: feedLabel.bottom
                anchors.left: feedLabel.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.rightMargin: Theme.paddingMedium
                color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                opacity: (model.read && ! model.shelved) ? 0.5 : 1
                textFormat: Text.PlainText
                text: replaceEntities(model.title)
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
                clip: true
                source: model.thumbnail
            }

            Image {
                visible: model.enclosures.length > 0
                anchors.top: parent.top
                anchors.right: parent.right
                source: "image://theme/icon-s-attach"
            }

            onClicked: {
                listview.currentIndex = index;
                var props = {
                    "index": index,
                    "listview": listview
                };
                pageStack.push("ViewPage.qml", props);
            }
        }

        section.property: "sectionTitle"
        section.criteria: ViewSection.FullString
        section.delegate: SectionHeader {
            text: section
        }

        ViewPlaceholder {
            enabled: sourcesModel.count === 0
            text: qsTr("Pull down to add feeds.")
        }

        ScrollDecorator { }
    }

    FancyScroller {
        visible: listview.quickScroll === undefined ||
                 listview.quickScrollEnabled !== true
        flickable: listview
    }

    /*
    BusyIndicator {
        anchors.centerIn: parent
        running: newsBlendModel.busy
        size: BusyIndicatorSize.Large
    }
    */

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
