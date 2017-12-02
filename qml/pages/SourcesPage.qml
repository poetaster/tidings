import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "SourcesPage"

    property Page feedsPage

    property var cycleThumbnailSources: []
    property int cycleIndex

    // edit modes:
    //   0: none
    //   1: edit feeds
    //   2: move feeds
    property int editMode: 0
    property int editedIndex: 0

    function titleText(editMode)
    {
        if (editMode === 0)
            return qsTr("Feeds");
        else if (editMode === 1 || editMode === 2)
            return qsTr("Manage feeds")
        else
            return "";
    }

    allowedOrientations: Orientation.All

    forwardNavigation: editMode === 0

    onStatusChanged: {
        if (status === PageStatus.Active && ! feedsPage) {
            console.log("attach page " + pageStack.depth);
            feedsPage = pageStack.pushAttached("FeedsPage.qml", {});
        }
    }

    onEditModeChanged: {
        if (editMode === 0)
        {
            sourcesModel.savePositions();
        }
    }

    Timer {
        running: Qt.application.active &&
                 page.status === PageStatus.Active &&
                 configShowPreviewImages.booleanValue &&
                 page.editMode !== 2
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

            if (cycleThumbnailSources.length > 0)
            {
                page.cycleIndex = cycleThumbnailSources.pop();
            }
        }
    }

    MouseArea {
        visible: page.editMode !== 0
        anchors.fill: parent

        onPressAndHold: {
            if (page.editMode === 1)
            {
                page.editMode = 0;
            }
        }

        onClicked: {
            if (page.editMode === 1)
            {
                page.editMode = 0;
            }
        }
    }

    RemorsePopup {
        id: remorse
    }

    SilicaGridView {
        id: gridview

        property int itemsPerRow: Math.floor(page.width / Theme.itemSizeHuge)

        cellWidth: width / itemsPerRow
        cellHeight: cellWidth * (3 / 4)

        // pad rows with clickable empty items
        model: Math.ceil(sourcesModel.count / itemsPerRow) * itemsPerRow;

        anchors.fill: parent
        anchors.leftMargin: page.editMode === 0 ? 0 : Theme.paddingLarge

        interactive: page.editMode !== 2

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        header: PageHeader {
            title: titleText(page.editMode)

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    if (page.editMode === 0)
                    {
                        page.editMode = 1;
                    }
                    else if (page.editMode === 1)
                    {
                        page.editMode = 0;
                    }
                }

                onClicked: {
                    if (page.editMode === 1)
                    {
                        page.editMode = 0;
                    }
                }
            }
        }

        footer: MouseArea {
            visible: page.editMode !== 0
            width: gridview.width
            height: visible ? gridview.cellHeight : 0

            // [add feed] button
            MouseArea {
                scale: page.editMode === 1 ? 1 : 0.05
                visible: scale > 0.1

                width: gridview.cellWidth
                height: gridview.cellHeight

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

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

            onPressAndHold: {
                if (page.editMode === 1)
                {
                    page.editMode = 0;
                }
            }

            onClicked: {
                if (page.editMode === 1)
                {
                    page.editMode = 0;
                }
            }
        }

        PullDownMenu {
            id: pulleyMenu

            property var _action

            visible: page.editMode === 0

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
                    remorse.execute(qsTr("All read"),
                                    function()
                                    {
                                        newsBlendModel.setAllRead();
                                    } );
                }
            }

            MenuItem {
                text: newsBlendModel.busy ? qsTr("Abort refreshing")
                                          : qsTr("Refresh all")

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
                    "mayDelete": sourcesModel.count > 1,
                    "item": listItem
                }
                pageStack.push("SourceEditDialog.qml", props);
            }

            function refresh()
            {
                newsBlendModel.refresh(item);
            }

            function forgetRead()
            {
                sourcesModel.forgetSourceRead(item.url);
                newsBlendModel.setFeedRead(item.url, false);
            }

            function remove()
            {
                newsBlendModel.removeFeedItems(item.url);
                sourcesModel.removeSource(item.sourceId);
            }

            width: gridview.cellWidth
            height: gridview.cellHeight

            onItemChanged: {
                if (item && ! itemContent.loadingStatus)
                {
                    itemContent.loadThumbnails();
                }
            }

            MouseArea {
                visible: index >= sourcesModel.count || page.editMode === 1
                anchors.fill: parent

                onPressAndHold: {
                    if (page.editMode === 0)
                    {
                        page.editMode = 1;
                    }
                    else if (page.editMode === 1)
                    {
                        page.editMode = 0;
                    }
                }

                onClicked: {
                    if (page.editMode === 1)
                    {
                        page.editMode = 0;
                    }
                }
            }

            FeedItem {
                id: itemContent
                visible: index < sourcesModel.count

                anchors.fill: parent

                opacity: (page.editMode === 2 && page.editedIndex === index) ? 0 : 1
                scale: page.editMode === 0 ? 1 : 0.66

                function loadThumbnails()
                {
                    thumbnails = newsBlendModel.thumbnailsOfFeed(item.url);
                    logo = newsBlendModel.logoOfFeed(item.url);
                }

                Behavior on scale {
                    enabled: page.editMode !== 2
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

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

                onLoadingStatusChanged: {
                    if (! loadingStatus)
                    {
                        loadThumbnails();
                    }
                }

                onClicked: {
                    if (page.editMode === 0 && totalCount !== 0)
                    {
                        newsBlendModel.selectedFeed = item.url;
                        feedsPage.positionAtFirst(item.url);
                        pageStack.navigateForward();
                    }
                    else if (page.editMode === 1)
                    {
                        parent.refresh();
                    }
                }

                onPressAndHold: {
                    if (page.editMode === 0)
                    {
                        page.editMode = 1;
                    }
                    else if (page.editMode === 1)
                    {
                        page.editMode = 2;
                        page.editedIndex = index;

                        floatingItem.grabOffsetX = mouse.x;
                        floatingItem.grabOffsetY = mouse.y;

                        floatingItem.name = name;
                        floatingItem.timestamp = timestamp;
                        floatingItem.colorTag = colorTag;
                        floatingItem.totalCount = totalCount;
                        floatingItem.unreadCount = unreadCount;
                        floatingItem.busy = busy;
                        floatingItem.thumbnails = thumbnails;
                        floatingItem.logo = logo;
                        floatingItem._thumbnailOffset = _thumbnailOffset;

                        var screenCoords = mapToItem(gridview, mouse.x, mouse.y);
                        floatingItem.x = screenCoords.x - floatingItem.grabOffsetX;
                        floatingItem.y = screenCoords.y - floatingItem.grabOffsetY;
                    }
                }

                onPressedButtonsChanged: {
                    if (pressedButtons === 0 && page.editMode === 2)
                    {
                        page.editMode = 1;
                    }
                }

                onPositionChanged: {
                    if (page.editMode === 2)
                    {
                        var screenCoords = mapToItem(gridview, mouse.x, mouse.y);

                        var newIndex = gridview.indexAt(gridview.contentX + screenCoords.x,
                                                        gridview.contentY + screenCoords.y);

                        if (newIndex !== -1 &&
                                newIndex < sourcesModel.count &&
                                newIndex !== page.editedIndex)
                        {
                            sourcesModel.moveItem(page.editedIndex, newIndex);
                            page.editedIndex = newIndex;

                            //gridview.positionViewAtIndex(Math.min(gridview.count, newIndex + gridview.itemsPerRow), GridView.Contain);
                            //gridview.positionViewAtIndex(Math.max(0, newIndex - gridview.itemsPerRow), GridView.Contain);
                        }
                        floatingItem.x = screenCoords.x - floatingItem.grabOffsetX;
                        floatingItem.y = screenCoords.y - floatingItem.grabOffsetY;
                    }
                }
            }

            // [edit] button
            MouseArea {
                scale: (itemContent.visible && page.editMode === 1) ? 1
                                                                    : 0.05
                visible: scale > 0.1

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Theme.paddingSmall

                width: editIcon.width + 2 * Theme.paddingSmall
                height: width

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: parent.pressed ? Theme.rgba(Theme.highlightColor, 0.2)
                                          : Theme.rgba(Theme.primaryColor, 0.2)
                }

                Image {
                    id: editIcon
                    anchors.centerIn: parent
                    source: "image://theme/icon-s-edit?" +
                            (parent.pressed ? Theme.highlightColor : Theme.primaryColor)

                }

                onClicked: {
                    listItem.edit();
                }
            }
        }

        // floating item
        FeedItem {
            id: floatingItem
            visible: page.editMode === 2

            property real grabOffsetX: 0
            property real grabOffsetY: 0

            width: gridview.cellWidth
            height: gridview.cellHeight
        }

        ScrollDecorator { }
    }

    MouseArea {
        visible: page.editMode !== 0 &&
                 gridview.contentHeight < parent.height
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height - gridview.contentHeight

        onPressAndHold: {
            if (page.editMode === 1)
            {
                page.editMode = 0;
            }
        }

        onClicked: {
            if (page.editMode === 1)
            {
                page.editMode = 0;
            }
        }
    }


    HintLoader {
        hint: feedsHint
        when: configHintsEnabled.booleanValue &&
              page.status === PageStatus.Active &&
              newsBlendModel.ready
    }

    HintLoader {
        hint: manageFeedsHint
        when: configHintsEnabled.booleanValue &&
              page.status === PageStatus.Active &&
              page.editMode === 1
    }

}
