import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "SourcesPage"

    property Page feedsPage

    property var cycleThumbnailSources: []
    property int cycleIndex

    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active && ! feedsPage) {
            console.log("attach page " + pageStack.depth);
            feedsPage = pageStack.pushAttached("FeedsPage.qml", {});
        }
    }

    Timer {
        running: Qt.application.active &&
                 page.status === PageStatus.Active &&
                 configShowPreviewImages.booleanValue
        interval: 2000
        repeat: true

        onTriggered: {
            if (cycleThumbnailSources.length === 0)
            {
                var temp = [];
                for (var i = 0; i < sourcesModel.count; ++i)
                {
                    temp.push(i);
                }
                while (temp.length > 0)
                {
                    i = Math.floor(Math.random() * temp.length);
                    cycleThumbnailSources.push(temp[i]);
                    temp.splice(i, 1);
                }
            }
            page.cycleIndex = cycleThumbnailSources.pop();
        }
    }

    RemorsePopup {
        id: remorse
    }

    SilicaGridView {
        id: gridview

        property int itemsPerRow: bigScreen ? (page.width > page.height ? 6 : 4)
                                            : (page.width > page.height ? 5 : 3)
        property int expandedIndex: -1
        property int minOffsetIndex: expandedIndex !== -1
                                     ? expandedIndex + itemsPerRow - (expandedIndex % itemsPerRow)
                                     : 0


        cellWidth: width / itemsPerRow
        cellHeight: cellWidth * (3 / 4)

        model: sourcesModel.count + 1

        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Feeds")
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
                text: qsTr("About Tidings")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                }
            }

            MenuItem {
                text: qsTr("Settings")

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                }
            }

            MenuItem {
                text: qsTr("All read")

                onClicked: {
                    pulleyMenu._action = function() {
                        remorse.execute(qsTr("All read"),
                                        function()
                                        {
                                            newsBlendModel.setAllRead();
                                        } );
                    };
                }
            }

            MenuItem {
                text: newsBlendModel.busy ? qsTr("Abort refreshing")
                                          : qsTr("Refresh")

                onClicked: {
                    pulleyMenu._action = function() {
                        if (newsBlendModel.busy) {
                            newsBlendModel.abort();
                        } else {
                            newsBlendModel.refreshAll();
                        }
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

        delegate: Item {
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

            function setFeedRead()
            {
                function closure(item, newsBlendModel)
                {
                    return function f()
                    {
                        newsBlendModel.setFeedRead(item.url, true);
                    }
                }

                var remorseItem = remorseComponent.createObject(itemContent);
                remorseItem.execute(itemContent, qsTr("All read"),
                                    closure(item, newsBlendModel));
            }

            function forgetRead()
            {
                function closure(item, sourcesModel, newsBlendModel)
                {
                    return function f()
                    {
                        sourcesModel.forgetSourceRead(item.url);
                        newsBlendModel.setFeedRead(item.url, false);
                    }
                }

                var remorseItem = remorseComponent.createObject(itemContent);
                remorseItem.execute(itemContent, qsTr("Clearing"),
                                    closure(item, sourcesModel, newsBlendModel));

            }

            function remove()
            {
                function closure(item, sourcesModel, newsBlendModel)
                {
                    return function f()
                    {
                        newsBlendModel.removeFeedItems(item.url);
                        sourcesModel.removeSource(item.sourceId);
                    }
                }

                var remorseItem = remorseComponent.createObject(itemContent);
                remorseItem.execute(itemContent, qsTr("Deleting"),
                                    closure(item, sourcesModel, newsBlendModel));
            }

            width: gridview.cellWidth
            height: gridview.cellHeight + contextMenu.height
            z: isExpanded ? 1000 : 1

            FeedItem {
                id: itemContent
                visible: index < sourcesModel.count

                y: parent.yOffset
                width: parent.width
                height: gridview.cellHeight

                // always update the feedInfo when the page becomes visible
                property variant feedInfo: ((page.status === PageStatus.Active ||
                                             Qt.application.active) &&
                                            item &&
                                            newsBlendModel.feedInfo)
                                           ? newsBlendModel.feedInfo.stats[item.url]
                                           : null

                property bool loadingStatus: feedInfo ? feedInfo.loading : false

                name: item ? item.name : ""
                timestamp: (feedInfo && feedInfo.lastRefresh)
                           ? feedInfo.lastRefresh
                           : function() { return new Date(0); }()
                colorTag: item ? item.color : "black"
                totalCount: feedInfo ? feedInfo.count : 0
                unreadCount: feedInfo ? feedInfo.unreadCount : 0
                busy: feedInfo ? feedInfo.loading : false

                Connections {
                    target: page
                    onCycleIndexChanged: {
                        if (page.cycleIndex === index)
                        {
                            if (itemContent.thumbnails.length > 1)
                            {
                                itemContent.cycleThumbnails();
                            }
                            else if (page.cycleThumbnailSources.length > 0)
                            {
                                page.cycleIndex = page.cycleThumbnailSources.pop();
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    if (item)
                    {
                        thumbnails = newsBlendModel.thumbnailsOfFeed(item.url);
                        logo = newsBlendModel.logoOfFeed(item.url);
                    }
                }

                onLoadingStatusChanged: {
                    if (! loadingStatus)
                    {
                        thumbnails = newsBlendModel.thumbnailsOfFeed(item.url);
                        logo = newsBlendModel.logoOfFeed(item.url);
                    }
                }

                onClicked: {
                    if (totalCount !== 0)
                    {
                        newsBlendModel.selectedFeed = item.url;
                        feedsPage.positionAtFirst(item.url);
                        pageStack.navigateForward();
                    }
                }

                onPressAndHold: {
                    gridview.expandedIndex = index;
                    contextMenu.show(listItem);
                }
            }

            // [add feed] item
            MouseArea {
                visible: ! itemContent.visible
                y: parent.yOffset
                width: parent.width
                height: gridview.cellHeight

                Image {
                    anchors.centerIn: parent
                    source: "image://theme/icon-l-add?" +
                            (parent.pressed ? Theme.highlightColor : Theme.primaryColor)
                }

                onClicked: {
                    var props = {
                        "url": "http://"
                    };
                    var dlg = pageStack.push("SourceEditDialog.qml", props);
                }
            }
        }

        ScrollDecorator { }

        ContextMenu {
            id: contextMenu
            property var _action

            onActiveChanged: {
                if (! active && _action)
                {
                    _action();
                    _action = null;
                }
            }

            MenuItem {
                text: qsTr("Refresh")

                onClicked: {
                    contextMenu._action = function() {
                        contextMenu.parent.refresh();
                    };
                }
            }

            MenuItem {
                text: qsTr("All read")

                onClicked: {
                    contextMenu._action = function() {
                        contextMenu.parent.setFeedRead();
                    };
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
            id: remorseComponent

            RemorseItem {
                wrapMode: Text.Wrap
            }
        }

    }
}
