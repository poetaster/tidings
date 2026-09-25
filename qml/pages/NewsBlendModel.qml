import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

/* List model that blends various feed models together.
 */
NewsModel {
    property bool debug: false
    id: listModel

    sortMode: feedSorter.sortMode
    unreadOnly: configShowOnlyUnread.booleanValue


    // whether to blend models or show a single feed
    // Must be set to "true" initially so the attached feeds page shows all
    // feeds on startup.
    property bool isBlendModeEnabled: true

    // the sorter for this model
    property FeedSorter feedSorter: _getFeedSorter(isBlendModeEnabled ? configAllFeedsSorter.value : configFeedSorter.value)

    // the list of all feed sources to load.
    property variant sources: []

    property var feedInfo: FeedStats { }

    // the time of the last refresh
    property variant lastRefresh

    // flag indicating that this model is ready
    // (the ready property is provided by the C++ NewsModel base class and
    //  is set after loadPersisted() has finished loading from the database)

    // flag indicating that this model is busy
    property bool busy: false

    // name of the feed currently loading
    property string currentlyLoading

    property FeedSorter latestFirstSorter: FeedSorter {
        key: "latestFirst"
        name: qsTr("Latest first")
        sortMode: NewsModel.LatestFirst
    }

    property FeedSorter oldestFirstSorter: FeedSorter {
        key: "oldestFirst"
        name: qsTr("Oldest first")
        sortMode: NewsModel.OldestFirst
    }

    property FeedSorter feedSourceLatestFirstSorter: FeedSorter {
        key: "feedLatestFirst"
        name: qsTr("Feed, then latest first")
        sortMode: NewsModel.FeedLatestFirst
    }

    property FeedSorter feedSourceOldestFirstSorter: FeedSorter {
        key: "feedOldestFirst"
        name: qsTr("Feed, then oldest first")
        sortMode: NewsModel.FeedOldestFirst
    }

    property FeedSorter feedOnlyLatestFirstSorter: FeedSorter {
        key: "feedOnlyLatestFirst"
        name: qsTr("Current feed only, latest first")
        sortMode: NewsModel.FeedOnlyLatestFirst
    }

    property FeedSorter feedOnlyOldestFirstSorter: FeedSorter {
        key: "feedOnlyOldestFirst"
        name: qsTr("Current feed only, oldest first")
        sortMode: NewsModel.FeedOnlyOldestFirst
    }

    property variant feedSorters: [
        latestFirstSorter,
        oldestFirstSorter,
        feedSourceLatestFirstSorter,
        feedSourceOldestFirstSorter,
        feedOnlyLatestFirstSorter,
        feedOnlyOldestFirstSorter
    ]

    property variant feedSortersSingle: [
        feedOnlyLatestFirstSorter,
        feedOnlyOldestFirstSorter
    ]

    property variant feedSortersCombined: [
        latestFirstSorter,
        oldestFirstSorter,
        feedSourceLatestFirstSorter,
        feedSourceOldestFirstSorter
    ]

    property FeedLoader _feedLoader: FeedLoader {
        property string feedName

        onSuccess: {
            listModel.feedInfoChanged();

            switch (type)
            {
            case FeedLoader.RSS2:
                if(debug) console.log("RSS2 format detected");
                _rssModel.xml = data;
                break;
            case FeedLoader.RDF:
                if(debug) console.log("RDF format defected");
                _rdfModel.xml = data;
                break;
            case FeedLoader.Atom:
                if(debug) console.log("Atom format detected");
                _atomModel.xml = data;
                break;
            case FeedLoader.OPML:
                if(debug)console.log("OPML format detected");
                _opmlModel.xml = data;
                break;
            default:
                _handleError("Unsupported feed format.");
                _loadNext();
                break;
            }
        }

        onError: {
            listModel.feedInfoChanged();

            _handleError(details);
            _loadNext();
        }
    }



    property FeedParser _atomModel: FeedParser {
        parserUrl: Qt.resolvedUrl("AtomModel.qml")
        onParserStatusChanged: _handleParserResult(this)
    }

    property FeedParser _opmlModel: FeedParser {
        parserUrl: Qt.resolvedUrl("OpmlModel.qml")
        onParserStatusChanged: _handleParserResult(this)
    }

    property FeedParser _rdfModel: FeedParser {
        parserUrl: Qt.resolvedUrl("RdfModel.qml")
        onParserStatusChanged: _handleParserResult(this)
    }

    property FeedParser _rssModel: FeedParser {
        parserUrl: Qt.resolvedUrl("RssModel.qml")
        onParserStatusChanged: _handleParserResult(this)
    }


    // queue of feed sources to process
    property var _sourcesQueue: []

    signal error(string details)

    function _handleParserResult(parser)
    {
        if(debug) console.log(parser.parserUrl + " status = " + parser.parserStatus);
        if (parser.xml)
        {
            if (parser.parserStatus === XmlListModel.Error)
            {
                _handleError(parser.errorString());
                _loadNext();
            }
            else if (parser.parserStatus === XmlListModel.Ready)
            {
                _loadFromFeed(parser.item);
            }
        }
    }

    function _getFeedSorter(key)
    {
        if(debug) console.log("get feed sorter for " + key);
        for (var i = 0; i < feedSorters.length; ++i)
        {
            if (feedSorters[i].key === key)
            {
                if(debug) console.log("using feed sorter " + feedSorters[i].key + " " + feedSorters[i].sortMode);
                return feedSorters[i];
            }
        }
        return null;
    }

    function _updateStats()
    {
        if(debug) console.log("updating stats");
        feedInfo.setTotalCounts(totalStats());
        feedInfo.setUnreadCounts(unreadStats());
        feedInfoChanged();
    }

    /* Takes the next source from the sources queue and loads it.
     */
    function _loadNext()
    {
        if (_feedLoader.source)
        {
            feedInfo.setLoading(_feedLoader.source, false);
        }

        if (_sourcesQueue.length > 0)
        {
            var source = _sourcesQueue.shift();
            var url = source.url;
            var name = source.name;

            if(debug) console.log("Now loading: " + name);
            currentlyLoading = name;
            busy = true;

            feedInfo.setLoading(url, true);
            feedInfo.setRefreshed(url);

            _feedLoader.feedName = name;
            _feedLoader.source = url;
        }
        else
        {
            currentlyLoading = "";
            busy = false;
            _updateStats();
        }
    }

    /* Handles errors.
     */
    function _handleError(error) {
        if(debug) console.log(error);
        var feedName = currentlyLoading + "";
        if (error.substring(0, 5) === "Host ") {
            // Host ... not found
            listModel.error(qsTr("Error with %1:\n%2")
                            .arg(feedName)
                            .arg(error));
        } else if (error.indexOf(" - server replied: ") !== -1) {
            var idx = error.indexOf(" - server replied: ");
            var reply = error.substring(idx + 19);
            listModel.error(qsTr("Error with %1:\n%2")
                            .arg(feedName)
                            .arg(reply));
        } else {
            listModel.error(qsTr("Error with %1:\n%2")
                            .arg(feedName)
                            .arg(error));
        }
    }

    /* Loads items from the given feed model.
     *
     * The per-item processing (deduplication, read checks) and the
     * offline caching are all done in C++ in one go.
     */
    function _loadFromFeed(feedModel)
    {
        loadFromFeedModel(feedModel,
                          "" + _feedLoader.source,
                          "" + _feedLoader.logo,
                          database);
        _updateStats();
        _loadNext();
    }

    /* Clears and reloads the model from the current sources.
     */
    function refreshAll()
    {
        for (var i = 0; i < sources.length; ++i)
        {
            feedInfo.setLoading(sources[i].url, true);
            if(debug) console.log("Source: " + sources[i].url);
            _sourcesQueue.push(sources[i]);
        }

        // remove all read, but not shelved items
        listModel.removeReadItems();
        _updateStats();

        if (! busy)
        {
            _loadNext();
            lastRefresh = new Date();
        }
    }

    /* Refreshes the model from the given source.
     */
    function refresh(source)
    {
        feedInfo.setLoading(source.url, true);

        // remove all read, but not shelved items from that source
        listModel.removeReadItems(source.url);
        _updateStats();

        _sourcesQueue.push(source);
        if (! busy)
        {
            _loadNext();
            lastRefresh = new Date();
        }
    }

    /* Loads the persisted items.
     *
     * The loading happens on a background thread in C++; once it has
     * finished, the model emits readyChanged().
     */
    function loadPersistedItems()
    {
        for (var i = 0; i < sources.length; ++i)
        {
            feedInfo.setLoading(sources[i].url, true);
        }

        loadPersisted(database);
    }

    onReadyChanged: {
        if (ready) {
            for (var i = 0; i < sources.length; ++i)
            {
                feedInfo.setLoading(sources[i].url, false);
            }
            _updateStats();
        }
    }

    /* Aborts loading.
     */
    function abort()
    {
        _sourcesQueue = [];
        _feedLoader.abort();

        _atomModel.xml = "";
        _rssModel.xml = "";
        _rdfModel.xml = "";
        _opmlModel.xml = "";

        for (var i = 0; i < sources.length; ++i)
        {
            feedInfo.setLoading(sources[i].url, false);
        }
        busy = false;

        _updateStats();
    }

    /* Retrieves the content of the given feed item.
     */
    function itemBody(source, uid)
    {
        if(debug) console.log("itemBody: " + source + ", " + uid);
        var body = database.itemBody(source, uid);
        if (body !== "")
        {
            return body;
        }
        else
        {
            // handle legacy items
            var jsonDoc = database.cachedItem(source, uid);
            if (jsonDoc !== "")
            {
                var item = json.fromJson(jsonDoc);
                return item.encoded.length > 0 ? item.encoded
                                               : item.description;
            }
            return "";
        }
    }

    function tidyCache()
    {
        if(debug) console.log("Clearing read items from cache");
        database.uncacheReadItems();
        database.forgetRead(3600 * 24 * 500);
    }

    onShelvedChanged: {
        if (listModel.isShelved(index))
        {
            database.shelveItem(getAttribute(index, "source"),
                                getAttribute(index, "uid"));
        }
        else
        {
            database.unshelveItem(getAttribute(index, "source"),
                                  getAttribute(index, "uid"));
        }
    }

    onReadChanged: {
        database.setItemsRead(items);
        _updateStats();
    }

}
