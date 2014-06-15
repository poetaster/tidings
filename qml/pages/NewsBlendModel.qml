import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0
import "database.js" as Database

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

    // flag indicating that this model is busy
    property bool busy: false

    // name of the feed currently loading
    property string currentlyLoading

    property FeedSorter latestFirstSorter: FeedSorter {
        key: "latestFirst"
        name: qsTr("Latest first")
        sortMode: NewsModel.LatestFirst
        getSection: function(feedName, date)
        {
            return Format.formatDate(date, Formatter.TimepointSectionRelative);
        }
    }

    property FeedSorter oldestFirstSorter: FeedSorter {
        key: "oldestFirst"
        name: qsTr("Oldest first")
        sortMode: NewsModel.OldestFirst
        getSection: function(feedName, date)
        {
            return Format.formatDate(date, Formatter.TimepointSectionRelative);
        }
    }

    property FeedSorter feedSourceLatestFirstSorter: FeedSorter {
        key: "feedLatestFirst"
        name: qsTr("Feed, then latest first")
        sortMode: NewsModel.FeedLatestFirst
        getSection: function(feedName, date)
        {
            return feedName;
        }
    }

    property FeedSorter feedSourceOldestFirstSorter: FeedSorter {
        key: "feedOldestFirst"
        name: qsTr("Feed, then oldest first")
        sortMode: NewsModel.FeedOldestFirst
        getSection: function(feedName, date)
        {
            return feedName;
        }
    }

    property variant feedSorters: [
        latestFirstSorter,
        oldestFirstSorter,
        feedSourceLatestFirstSorter,
        feedSourceOldestFirstSorter
    ]

    property FeedLoader _feedLoader: FeedLoader {
        property string feedName
        property string feedColor

        onSuccess: {
            feedInfo.setLoading(source, false);
            listModel.feedInfoChanged();

            switch (type)
            {
            case FeedLoader.RSS2:
                console.log("RSS2 format detected");
                _rssModel.xml = "";
                _rssModel.xml = data;
                break;
            case FeedLoader.RDF:
                console.log("RDF format defected");
                _rdfModel.xml = "";
                _rdfModel.xml = data;
                break;
            case FeedLoader.Atom:
                console.log("Atom format detected");
                _atomModel.xml = "";
                _atomModel.xml = data;
                break;
            case FeedLoader.OPML:
                console.log("OPML format detected");
                _opmlModel.xml = "";
                _opmlModel.xml = data;
                break;
            default:
                _handleError("Unsupported feed format.");
                _loadNext();
                break;
            }
        }

        onError: {
            feedInfo.setLoading(source, false);
            listModel.feedInfoChanged();

            _handleError(details);
            _loadNext();
        }
    }


    // worker for running tasks in the background
    property BackgroundWorker _backgroundWorker: BackgroundWorker { }

    property RssModel _rssModel: RssModel {
        onStatusChanged: {
            if (source)
            {
                console.log("RssModel.status = " + status + " (" + source + ")");
                if (status === XmlListModel.Error)
                {
                    _handleError(errorString());
                    _loadNext();
                }
                else if (status === XmlListModel.Ready)
                {
                    _loadFromFeed(_rssModel);
                }
            }
        }
    }

    property RssModel _rdfModel: RdfModel {
        onStatusChanged: {
            if (source)
            {
                console.log("RdfModel.status = " + status + " (" + source + ")");
                if (status === XmlListModel.Error)
                {
                    _handleError(errorString());
                    _loadNext();
                }
                else if (status === XmlListModel.Ready)
                {
                    _loadFromFeed(_rdfModel);
                }
            }
        }
    }

    property AtomModel _atomModel: AtomModel {
        onStatusChanged: {
            if (source)
            {
                console.log("AtomModel.status = " + status + " (" + source + ")");
                if (status === XmlListModel.Error)
                {
                    _handleError(errorString());
                    _loadNext();
                }
                else if (status === XmlListModel.Ready)
                {
                    _loadFromFeed(_atomModel);
                }
            }
        }
    }

    property OpmlModel _opmlModel: OpmlModel {
        onStatusChanged: {
            if (source)
            {
                console.log("OpmlModel.status = " + status + " (" + source + ")");
                if (status === XmlListModel.Error)
                {
                    _handleError(errorString());
                    _loadNext();
                }
                else if (status === XmlListModel.Ready)
                {
                    _loadFromFeed(_opmlModel);
                }
            }
        }
    }

    property var _sourcesQueue: []

    signal error(string details)

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

    function _createItem(obj)
    {
        var item = { };
        for (var key in obj)
        {
            item[key] = obj[key];
        }
        return item;
    }

    /*
    function _ensureFeedInfo(url)
    {
        if (! feedInfo[url])
        {
            feedInfo[url] = {
                "lastRefresh": null,
                "loading": false,
                "count": 0,
                "unreadCount": 0
            }
        }
    }

    function _feedInfoCountReset(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].count = 0;
        feedInfoChanged();
    }

    function _feedInfoCountIncrement(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].count += 1;
        feedInfoChanged();
    }

    function _feedInfoCountDecrement(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].count -= 1;
        feedInfoChanged();
    }

    function _feedInfoUnreadCountReset(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].unreadCount = 0;
        feedInfoChanged();
    }

    function _feedInfoUnreadCountDecrement(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].unreadCount -= 1;
        feedInfoChanged();
    }

    function _feedInfoUnreadCountIncrement(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].unreadCount += 1;
        feedInfoChanged();
    }

    function _feedInfoRefreshed(url)
    {
        _ensureFeedInfo(url);
        feedInfo[url].lastRefresh = new Date();
        feedInfoChanged();
    }

    function _feedInfoSetLoading(url, value)
    {
        _ensureFeedInfo(url);
        feedInfo[url].loading = value;
        feedInfoChanged();
    }
    */

    /* Adds the item from the given model. Returns the new item if it was
     * inserted, or null otherwise.
     */
    function _loadItem(model, i)
    {
        console.log("get from model " + i);
        var item = _createItem(model.get(i));
        item["source"] = "" + _feedLoader.source; // convert to string
        item["date"] = item.dateString !== "" ? new Date(item.dateString)
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

        if (Database.isRead(item.source, item.uid))
        {
            // read items are gone
            return null;
        }

        /*
        // don't add item if shelved, because it will be taken off the shelf
        item["shelved"] = Database.isShelved(item.source, item.uid);
        if (item.shelved)
        {
            return;
        }
        */

        item["name"] = _feedLoader.feedName;
        item["color"] = _feedLoader.feedColor;

        listModel.addItem(item);

        return item;
    }

    /* Takes the next source from the sources queue and loads it.
     */
    function _loadNext()
    {
        if (_sourcesQueue.length > 0)
        {
            var source = _sourcesQueue.shift();
            var url = source.url;
            var name = source.name;
            var color = source.color;

            console.log("Now loading: " + name);
            currentlyLoading = name;
            busy = true;

            feedInfo.setLoading(url, true);
            feedInfo.setRefreshed(url);

            _feedLoader.feedColor = color;
            _feedLoader.feedName = name;
            _feedLoader.source = url;
        }
        else
        {
            currentlyLoading = "";
            busy = false;
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
        feedInfo.setLoading(_feedLoader.source, true);

        function loader()
        {
            if (index < feedModel.count)
            {
                var newItem = _loadItem(feedModel, index);
                if (newItem)
                {
                    feedInfo.increment(_feedLoader.source);
                    feedInfo.incrementUnread(_feedLoader.source);

                    var tuple = {
                        "url": newItem.source,
                        "uid": newItem.uid,
                        "document": json.toJson(newItem)
                    };
                    newItems.push(tuple);
                }
                ++index;
                return true;
            }
            else
            {
                Database.cacheItems(newItems);
                feedInfo.setLoading(_feedLoader.source, false);
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
        // remove all read, but not shelved items
        listModel.removeReadItems();

        for (var i = 0; i < sources.length; i++)
        {
            console.log("Source: " + sources[i].url);
            _sourcesQueue.push(sources[i]);
            feedInfo.reset(sources[i].url);
        }
        _loadNext();
        lastRefresh = new Date();
    }

    /* Refreshes the model from the given source.
     */
    function refresh(source)
    {
        // remove all read, but not shelved items from that source
        listModel.removeReadItems(source);

        _sourcesQueue.push(source);
        if (! busy)
        {
            feedInfo.reset(source.url);
            lastRefresh = new Date();
            _loadNext();
        }
    }

    /* Loads the persisted items.
     */
    function loadPersistedItems()
    {
        var shelvedCounts = Database.shelvedCounts();
        var cachedCounts = Database.cachedCounts();

        var i;
        var j;
        var keys = Object.keys(shelvedCounts);
        for (i = 0; i < keys.length; ++i)
        {
            for (j = 0; j < shelvedCounts[keys[i]]; ++j)
            {
                feedInfo.increment(keys[i]);
            }
        }

        keys = Object.keys(cachedCounts);
        for (i = 0; i < keys.length; ++i)
        {
            for (j = 0; j < cachedCounts[keys[i]]; ++j)
            {
                feedInfo.increment(keys[i]);
                feedInfo.incrementUnread(keys[i]);
            }
        }

        var jsons = Database.shelvedItems();
        loadItems(jsons, true);
        jsons = Database.cachedItems();
        loadItems(jsons, false);
    }

    /* Aborts loading.
     */
    function abort() {
        _sourcesQueue = [];
        _backgroundWorker.abort();
        feedInfo.setLoading(_feedLoader.source, false);
        busy = false;
    }

    /* Marks all items of the given source as read.
     */
    function setAllRead(source)
    {
        /*
        var pos = 0;
        busy = true;

        function marker()
        {
            if (pos < _items.length)
            {
                if (_items[pos].source === source)
                {
                    setRead(pos, true);
                }
                ++pos;
                return true;
            }
            else
            {
                busy = false;
                return false;
            }
        }

        _backgroundWorker.execute(marker);
        */
    }

    Component.onCompleted: {
        Database.forgetRead(3600 * 24 * 90);
    }

    onShelvedChanged: {
        console.log("shelved changed " + index);
        var item = listModel.getItem(index);
        if (listModel.isShelved(index))
        {
            Database.shelveItem(item.source, item.uid, json.toJson(item));
        }
        else
        {
            Database.unshelveItem(item.source, item.uid);
        }
    }

    onReadChanged: {
        var item = listModel.getItem(index);
        Database.setRead(item.source, item.uid, listModel.isRead(index));
        if (listModel.isRead(index))
        {
            feedInfo.decrementUnread(item.source);
        }
    }

    onSectionTitleRequested: {
        setSectionTitle(feedSorter.getSection(itemFeed, itemDate));

    }
}
