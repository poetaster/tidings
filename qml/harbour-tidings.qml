import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import harbour.tidings 1.0
import "pages"
import "cover"

ApplicationWindow
{
    id: appWin

    property alias feedName: sourcesModel.names
    property alias feedColor: sourcesModel.colors

    property bool bigScreen: width * height > 2000000

    property string imagePlaceholder: configLoadImages.booleanValue
                                      ? ""
                                      : Qt.resolvedUrl("pages/placeholder.png")

    allowedOrientations: Orientation.All

    Database {
        id: database
    }

    SourcesModel {
        id: sourcesModel

        onModelChanged: {
            var sources = [];
            for (var i = 0; i < count; i++) {
                sources.push(get(i));
            }
            newsBlendModel.sources = sources;
        }
    }

    NewsBlendModel {
        id: newsBlendModel

        onError: {
            console.log("Error: " + details);
            notification.show(details);
        }

        onReadyChanged: {
            if (ready)
            {
                database.vacuum();
                pageStack.replace(Qt.resolvedUrl("pages/SourcesPage.qml"));
            }
        }
    }

    QtObject {
        id: navigationState

        signal openedItem(int index)
    }

    QtObject {
        id: coverAdaptor

        property string feedName
        property string title
        property string thumbnail
        property string page
        property string currentPage: (pageStack.depth > 0)
                                     ? pageStack.currentPage.objectName
                                     : ""
        property variant lastRefresh: newsBlendModel.lastRefresh
        property int totalCount: newsBlendModel.count
        property bool busy: newsBlendModel.busy

        property bool hasPrevious
        property bool hasNext

        signal refresh
        signal abort
        signal firstItem
        signal previousItem
        signal nextItem
    }

    ConfigValue {
        id: configFeedSorter
        key: "feed-sort-by"
        value: "feedOnlyLatestFirst"
    }

    ConfigValue {
        id: configShowPreviewImages
        key: "feed-preview-images"
        value: "1"
    }

    ConfigValue {
        id: configLoadImages
        key: "view-load-images"
        value: "0"
    }

    ConfigValue {
        id: configTintedItems
        key: "feed-tinted"
        value: "1"
    }

    ConfigValue {
        id: configFontScale
        key: "font-scale"
        value: "100"
    }

    ConfigValue {
        id: configFontScaleWebEnabled
        key: "font-scale-web-enabled"
        value: "0"
    }

    ConfigValue {
        id: configHintsEnabled
        key: "hints-enabled"
        value: "1"
    }

    Timer {
        id: initTimer
        interval: 500
        running: true

        onTriggered: {
            if (sourcesModel.count === 0)
            {
                // add example feeds
                sourcesModel.addSource("Engadget",
                                       "http://www.engadget.com/rss.xml",
                                       "#ff0000");
                sourcesModel.addSource("JollaUsers.com",
                                       "http://jollausers.com/feed/",
                                       "#ffa000");
            }
            newsBlendModel.tidyCache();
            newsBlendModel.loadPersistedItems();
        }
    }

    Timer {
        id: minuteTimer

        property bool tick: true

        triggeredOnStart: true
        running: Qt.application.active
        interval: 60000
        repeat: true

        onTriggered: {
            tickChanged();
        }
    }

    Audio {
        id: audioPlayer

        property bool playing: playbackState === Audio.PlayingState
        property bool paused: playbackState === Audio.PausedState

        autoLoad: false
        autoPlay: false
    }

    Downloader {
        id: downloader
    }

    Notification {
        id: notification
    }

    Hint {
        id: feedsHint
        title: qsTr("Feeds overview")
        items: [qsTr("- Shows all your subscribed feeds."),
                qsTr("- Pull down to refresh all."),
                qsTr("- Tap and hold to add or manage feeds.")]
    }

    Hint {
        id: manageFeedsHint
        title: qsTr("Managing mode")
        items: [qsTr("- Tap on a feed to refresh."),
                qsTr("- Tap on the edit button to edit."),
                qsTr("- Tap and hold on a feed to move position."),
                qsTr("- Tap on empty space to leave managing mode.")]
    }

    Hint {
        id: articlesListHint
        title: qsTr("Articles")
        items: [qsTr("- Tap on the page header to change sorting."),
                qsTr("- Pull down to mark all as read.")]
    }

    Hint {
        id: articleHint
        title: qsTr("Article view")
        items: [qsTr("- Tap on the title to open in external browser."),
                qsTr("- Tap on the clipboard symbol to copy the link address to the clipboard."),
                qsTr("- Tap on the star symbol to keep this article.")]
    }

    initialPage: splashPage
    cover: coverPage

    Component {
        id: splashPage

        Page {
            allowedOrientations: Orientation.All

            Label {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.highlightColor
                text: qsTr("Loading from cache")
            }
        }
    }

    Component {
        id: coverPage

        CoverPage { }
    }
}
