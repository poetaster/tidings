import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "SourcesPage"

    property Page feedsPage

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    onStatusChanged: {
        if (status === PageStatus.Active && ! feedsPage) {
            console.log("attach page " + pageStack.depth);
            feedsPage = pageStack.pushAttached("FeedsPage.qml", {});
        }
    }

    SilicaGridView {
        id: gridview

        property int expandedIndex: -1
        property int minOffsetIndex: expandedIndex !== -1
                                     ? expandedIndex + 3 - (expandedIndex % 3)
                                     : 0

        cellWidth: page.width > page.height ? width / 5 : width / 3
        cellHeight: cellWidth

        model: sourcesModel.count + 1

        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Feeds")
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
                                          : qsTr("Refresh all")

                onClicked: {
                    if (newsBlendModel.busy) {
                        newsBlendModel.abort();
                    } else {
                        newsBlendModel.refreshAll();
                    }
                }
            }
        }

        delegate: MouseArea {
            id: listItem

            property bool isExpanded: contextMenu.active &&
                                      gridview.expandedIndex === index

            property real yOffset: index >= gridview.minOffsetIndex ? contextMenu.height
                                                                    : 0

            property variant item: index < sourcesModel.count ? sourcesModel.get(index)
                                                              : null


            function edit()
            {
                var props = {
                    "name": item.name,
                    "url": item.url,
                    "color": item.color,
                    "sourceId": item.sourceId,
                    "editOnly": true,
                    "item": listItem
                }
                pageStack.push("SourceEditDialog.qml", props);
            }

            function refresh()
            {
                newsBlendModel.refresh(item);
            }

            function markAllRead()
            {
                newsBlendModel.setAllRead(item.url);
            }

            function remove()
            {
                function closure(item, sourcesModel, newsBlendModel)
                {
                    return function f()
                    {
                        newsBlendModel.removeItems(item.url);
                        sourcesModel.removeSource(item.sourceId);
                    }
                }


                var remorseItem = remorseComponent.createObject(itemContent);
                remorseItem.execute(itemContent, qsTr("Deleting"),
                                    closure(item, sourcesModel, newsBlendModel));
            }

            width: gridview.cellWidth
            height: gridview.cellWidth + contextMenu.height
            z: isExpanded ? 1000 : 1

            enabled: ! newsBlendModel.busy

            Item {
                id: itemContent

                y: parent.yOffset
                width: parent.width
                height: gridview.cellHeight

                // feed item
                Loader {
                    anchors.fill: parent
                    sourceComponent: listItem.item ? feedComponent : null

                    onLoaded: {
                        item.item = listItem.item
                    }
                }

                // [add feed] item
                Image {
                    visible: item == null
                    anchors.centerIn: parent
                    source: "image://theme/icon-l-add"
                }


            }

            onClicked: {
                if (item)
                {
                    feedsPage.positionAtFirst(item.url);
                    pageStack.navigateForward();
                }
                else
                {
                    var props = {
                        "url": "http://"
                    };
                    var dlg = pageStack.push("SourceEditDialog.qml", props);
                }
            }

            onPressAndHold: {
                if (item)
                {
                    gridview.expandedIndex = index;
                    contextMenu.show(listItem);
                }
            }
        }

        ViewPlaceholder {
            enabled: gridview.count === 0
            text: qsTr("Pull down to add RSS, Atom, or OPML sources.")
        }

        ScrollDecorator { }

        ContextMenu {
            id: contextMenu

            MenuItem {
                text: qsTr("Refresh")

                onClicked: {
                    contextMenu.parent.refresh();
                }
            }

            MenuItem {
                text: qsTr("Mark all read")

                onClicked: {
                    contextMenu.parent.markAllRead();
                }
            }

            MenuItem {
                text: qsTr("Edit")

                onClicked: {
                    contextMenu.parent.edit();
                }
            }
        }

        Component {
            id: feedComponent

            Item {
                property variant item

                // always update the feedInfo when the page becomes visible
                property variant feedInfo: ((page.status === PageStatus.Active ||
                                             Qt.application.active) &&
                                            item &&
                                            newsBlendModel.feedInfo)
                                           ? newsBlendModel.feedInfo[item.url]
                                           : null

                anchors.fill: parent

                opacity: newsBlendModel.busy && ! busyIndicator.running ? 0.2
                                                                        : 1

                Behavior on opacity {
                    NumberAnimation { }
                }

                Rectangle {
                    width: 2
                    height: parent.height
                    color: item.color
                }

                Image {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    fillMode: Image.PreserveAspectFit
                    source: Qt.resolvedUrl("../cover/overlay.png")
                    opacity: 0.1
                }

                Label {
                    id: countLabel
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeHuge
                    color: Theme.primaryColor
                    text: feedInfo ? feedInfo.unreadCount
                                   : "0"
                }

                Label {
                    id: totalCountLabel
                    anchors.left: countLabel.right
                    anchors.baseline: countLabel.baseline
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    text: " / " + (feedInfo ? feedInfo.count
                                          : "0")
                }

                Label {
                    id: nameLabel

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.paddingSmall + 2
                    anchors.rightMargin: Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                    text: item.name
                }

                Label {
                    id: timeLabel

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: Theme.paddingSmall + 2
                    anchors.rightMargin: Theme.paddingSmall
                    anchors.bottomMargin: Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    elide: Text.ElideRight
                    text: feedInfo && feedInfo.lastRefresh && minuteTimer.tick
                          ? Format.formatDate(feedInfo.lastRefresh,
                                              Formatter.DurationElapsed)
                          : ""
                }

                BusyIndicator {
                    id: busyIndicator

                    running: feedInfo ? feedInfo.loading : false
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Medium
                }
            }
        }

        Component {
            id: remorseComponent

            RemorseItem {
                wrapMode: Text.Wrap
            }
        }

    }
}
