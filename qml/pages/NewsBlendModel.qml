import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

/* List model that blends various feed models together.
 */
NewsModel {
    id: listModel

    sortMode: feedSorter.sortMode

    // the sorter for this model
    property FeedSorter feedSorter: _getFeedSorter(configFeedSorter.value)

    // the list of all feed sources to load.
    property variant sources: []

    property var feedInfo: FeedStats { }

    // the time of the last refresh
    property variant lastRefresh

    // flag indicating that this model ready
    property bool ready: false

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

    property FeedLoader _feedLoader: FeedLoader {
        property string feedName

        onSuccess: {
            listModel.feedInfoChanged();

            switch (type)
            {
            case FeedLoader.RSS2:
                console.log("RSS2 format detected");
                _rssModel.xml = data;
                break;
            case FeedLoader.RDF:
                console.log("RDF format defected");
                _rdfModel.xml = data;
                break;
            case FeedLoader.Atom:
                console.log("Atom format detected");
                _atomModel.xml = data;
                break;
            case FeedLoader.OPML:
                console.log("OPML format detected");
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


    // worker for running tasks in the background
    property BackgroundWorker _backgroundWorker: BackgroundWorker { }

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
        console.log(parser.parserUrl + " status = " + parser.parserStatus);
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
        console.log("get feed sorter for " + key);
        for (var i = 0; i < feedSorters.length; ++i)
        {
            if (feedSorters[i].key === key)
            {
                console.log("using feed sorter " + feedSorters[i].key + " " + feedSorters[i].sortMode);
                return feedSorters[i];
            }
        }
        return null;
    }

    function _updateStats()
    {
        console.log("updating stats");
        feedInfo.setTotalCounts(totalStats());
        feedInfo.setUnreadCounts(unreadStats());
        feedInfoChanged();
    }

    /* Adds the item from the given model. Returns the new item if it was
     * inserted, or null otherwise.
     */
    function _loadItem(model, i)
    {
        // convert model item to an associative array
        var item = { };
        var obj = model.get(i);
        for (var key in obj)
        {
            item[key] = obj[key];
        }

        item["source"] = "" + _feedLoader.source; // convert to string
        item["logo"] = "" + _feedLoader.logo;
        item["date"] = item.dateString !== "" ? dateParser.parse(item.dateString)
                                              : new Date();

        if (item.uid === "")
        {
            // if there is no UID, make a unique one
            if (item.dateString !== "")
            {
                item["uid"] = item.title + item.dateString;
            }
            else
            {
                var d = new Date();
                item["uid"] = item.title + d.getTime();
            }
        }

        if (listModel.hasItem(item.source, item.uid))
        {
            // do not insert the same item twice
            return null;
        }

        if (database.isRead(item.source, item.uid) &&
            ! database.isShelved(item.source, item.uid))
        {
            // read items are gone
            return null;
        }

        listModel.addItem(item);

        return item;
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

            console.log("Now loading: " + name);
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
        console.log(error);
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
     */
    function _loadFromFeed(feedModel)
    {
        var index = 0;
        var newItems = [];

        function loader()
        {
            if (index < feedModel.count)
            {
                var newItem = _loadItem(feedModel, index);
                if (newItem)
                {
                    var body = newItem.encoded.length > 0 ? newItem.encoded
                                                          : newItem.description;

                    // do not store the body in the item
                    newItem["description"] = null;
                    newItem["encoded"] = null;

                    var tuple = {
                        "url": newItem.source,
                        "uid": newItem.uid,
                        "document": json.toJson(newItem),
                        "body": body
                    };
                    newItems.push(tuple);
                }
                ++index;
                return true;
            }
            else
            {
                database.cacheItems(newItems);
                _updateStats();
                _loadNext();
                return false;
            }
        }

        _backgroundWorker.execute(loader);
    }

    /* Clears and reloads the model from the current sources.
     */
    function refreshAll()
    {
        for (var i = 0; i < sources.length; ++i)
        {
            feedInfo.setLoading(sources[i].url, true);
            console.log("Source: " + sources[i].url);
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
     */
    function loadPersistedItems()
    {   
        for (var i = 0; i < sources.length; ++i)
        {
            feedInfo.setLoading(sources[i].url, true);
        }

        var mode = 0;
        var offset = 0;
        var batchSize = 500;

        function loader()
        {
            var rows;
            var jsons = [];
            var i;

            if (mode === 0)
            {
                rows = database.batchLoadCached(offset, batchSize);
                for (i = 0; i < rows.length; ++i)
                {
                    jsons.push(rows[i]);
                }
                loadItems(jsons, false);
                if (rows.length < batchSize)
                {
                    ++mode;
                    offset = 0;
                }
                else
                {
                    offset += batchSize;
                }
                return true;
            }
            else if (mode === 1)
            {
                rows = database.batchLoadShelved(offset, batchSize);
                for (i = 0; i < rows.length; ++i)
                {
                    jsons.push(rows[i]);
                }
                loadItems(jsons, true);
                if (rows.length < batchSize)
                {
                    ++mode;
                }
                else
                {
                    offset += batchSize;
                }
                return true;
            }
            else
            {
                for (i = 0; i < sources.length; ++i)
                {
                    feedInfo.setLoading(sources[i].url, false);
                }
                _updateStats();
                ready = true;
                return false;
            }
        }

        _backgroundWorker.execute(loader);
    }

    /* Aborts loading.
     */
    function abort()
    {
        _sourcesQueue = [];
        _feedLoader.abort();
        _backgroundWorker.abort();

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
        console.log("itemBody: " + source + ", " + uid);
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
        console.log("Clearing read items from cache");
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
