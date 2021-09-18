import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "FeedsPage"

    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status == PageStatus.Inactive && pageStack.currentPage.objectName == 'SourcesPage') {
            // Show all feeds again if we returned to the root page, i.e. the
            // feed sources overview page.
            // WARNING: This inevitably breaks if it becomes possible to reach the
            // combined news page from somewhere other than "SourcesPage".
            newsBlendModel.isBlendModeEnabled = true;
            listview.currentIndex = -1
        }

        // Uncomment to debug page changes.
        // if (status == PageStatus.Inactive) {
        //     console.log("FeedsPage inactive: status =", status, "depth =", pageStack.depth, "current = ", pageStack.currentPage.objectName)
        // }
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
            listview.currentIndex = 0;
            var props = {
                "index": 0,
                "listview": listview
            };
            pageStack.push("ViewPage.qml", props);
        }

        onRefresh: {
            newsBlendModel.refreshAll();
        }

        onAbort: {
            newsBlendModel.abort();
        }
    }

    RemorsePopup {
        id: remorse
    }

    //SilicaListView {
    SilicaGridView {
        id: listview

        anchors.fill: parent
        cellWidth: width > height ? width / 2 : width
        cellHeight: Theme.itemSizeLarge

        model: newsBlendModel

        header: PageHeader {
            title: qsTr("%1 items").arg(newsBlendModel.count)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SortSelectorPage.qml"));
                }
            }
        }

        PullDownMenu {
            id: pulleyMenu

            property var _action

            onActiveChanged: {
                if (! active && _action)
                {
                    _action();
                    _action = null;
                }
            }

            MenuItem {
                text: qsTr("Sort by: %1").arg(newsBlendModel.feedSorter.name)
                elide: Text.ElideRight

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SortSelectorPage.qml"));
                }
            }

            MenuItem {
                text: newsBlendModel.unreadOnly ? qsTr("Show all entries") : qsTr("Only show unread")
                onClicked: configShowOnlyUnread.value = (newsBlendModel.unreadOnly ? '0' : '1')
            }

            MenuItem {
                text: qsTr("All read")

                onClicked: {
                    pulleyMenu._action = function() {
                        remorse.execute(qsTr("All read"),
                                        function()
                                        {
                                            newsBlendModel.setVisibleRead();
                                        } );
                    };
                }
            }

            MenuItem {
                visible: audioPlayer.playing
                text: qsTr("Stop Audio")

                onClicked: {
                    audioPlayer.stop();
                    audioPlayer.source = "";
                }
            }
        }

        delegate: ListItem {
            id: feedItem

            property variant data: model

            width: listview.cellWidth
            contentHeight: listview.cellHeight
            clip: true

            Rectangle {
                visible: configTintedItems.booleanValue
                anchors.fill: parent
                color: feedColor[model.source]
                opacity: 0.1
            }

            Rectangle {
                width: 2
                height: parent.height
                color: feedColor[model.source]
            }

            IconButton {
                id: shelveIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                icon.source: model.shelved ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                onClicked: newsBlendModel.setShelved(model.index, !model.shelved)
            }

            Label {
                id: feedLabel
                anchors.left: shelveIcon.visible ? shelveIcon.right : parent.left
                anchors.right: picture.visible ? picture.left : parent.right
                anchors.leftMargin: shelveIcon.visible ? Theme.paddingSmall
                                                       : Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium
                color: feedItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: (minuteTimer.tick ? "" : "") +
                      feedName[model.source] + " (" +
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
                textFormat: Text.StyledText
                text: {
                    var t = model.title;
                    return t.replace("&", "&amp;");
                }

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
                source: configShowPreviewImages.booleanValue ? model.thumbnail : ""
            }

            Image {
                visible: model.enclosures.length > 0
                anchors.top: parent.top
                anchors.right: parent.right
                source: "image://theme/icon-s-attach"
            }

            onClicked: {
                listview.currentIndex = index;
                pageStack.push("ViewPageProxy.qml", { "listview": listview });
            }
        }

        ViewPlaceholder {
            enabled: sourcesModel.count === 0 || newsBlendModel.count === 0
            text: {
                if (sourcesModel.count === 0) return qsTr("No entries")
                else if (newsBlendModel.count === 0) {
                    if (newsBlendModel.unreadOnly) return qsTr("No unread entries")
                    else return qsTr("No entries")
                }
                else return ''
            }
            hintText: {
                if (sourcesModel.count === 0) return qsTr("Pull down to add feeds.")
                else return qsTr("Pull down to refresh.")
            }
        }

        ScrollDecorator { color: palette.primaryColor }
    }

    FancyScroller {
        visible: listview.quickScroll === undefined ||
                 listview.quickScrollEnabled !== true
        flickable: listview
    }


    // loading indicator
    Rectangle {
        visible: newsBlendModel.busy
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.itemSizeMedium
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: "black" }
            GradientStop { position: 1; color: "black" }
        }

        BusyIndicator {
            running: parent.visible
            size: BusyIndicatorSize.Small
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: loadingLabel.top
            anchors.bottomMargin: Theme.paddingSmall
        }

        Label {
            id: loadingLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            anchors.bottomMargin: Theme.paddingSmall
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.secondaryColor
            truncationMode: TruncationMode.Fade
            text: newsBlendModel.currentlyLoading
        }
    }

    HintLoader {
        hint: articlesListHint
        when: configHintsEnabled.booleanValue &&
              page.status === PageStatus.Active
    }
}
