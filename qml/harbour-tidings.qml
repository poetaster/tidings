import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import "pages"
import "cover"

ApplicationWindow
{
    property alias feedName: sourcesModel.names
    property alias feedColor: sourcesModel.colors

    property string imagePlaceholder: configLoadImages.booleanValue
                                      ? ""
                                      : Qt.resolvedUrl("pages/placeholder.png")

    SourcesModel {
        id: sourcesModel

        onModelChanged: {
            var sources = [];
            for (var i = 0; i < count; i++) {
                sources.push(get(i));
            }
            newsBlendModel.sources = sources;
        }

        Component.onCompleted: {
            if (count === 0) {
                // add example feeds
                addSource("Engadget",
                          "http://www.engadget.com/rss.xml",
                          "#ff0000");
                addSource("JollaUsers.com",
                          "http://jollausers.com/feed/",
                          "#ffa000");
            }
        }
    }

    NewsBlendModel {
        id: newsBlendModel

        onError: {
            console.log("Error: " + details);
            notification.show(details);
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

    Timer {
        id: initTimer
        interval: 500
        running: true

        onTriggered: {
            newsBlendModel.loadPersistedItems();
            pageStack.replace(sourcesPage);
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

    Notification {
        id: notification
    }

    initialPage: splashPage
    cover: coverPage

    Component {
        id: splashPage

        SplashPage { }
    }

    Component {
        id: sourcesPage

        SourcesPage { }
    }

    Component {
        id: coverPage

        CoverPage { }
    }
}
