import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0
import "database.js" as Database

/* List model that blends various feed models together.
 */
ListModel {
    id: listModel

    // the sorter for this model
    property FeedSorter feedSorter: _getFeedSorter(configFeedSorter.value)

    // the list of all feed sources to load.
    property variant sources: []

    property var feedInfo: ({ })

    // the time of the last refresh
    property variant lastRefresh

    // flag indicating that this model is busy
    property bool busy: false

    // name of the feed currently loading
    property string currentlyLoading

    // private list of items as JS dicts
    property var _items: []

    property FeedSorter latestFirstSorter: FeedSorter {
        key: "latestFirst"
        name: qsTr("Latest first")
        compare: function(a, b)
        {
            return (a.date < b.date) ? -1
                                     : (a.date === b.date) ? 0
                                                           : 1;
        }
        getSection: function(item)
        {
            return Format.formatDate(item.date, Formatter.TimepointSectionRelative);
        }
    }

    property FeedSorter oldestFirstSorter: FeedSorter {
        key: "oldestFirst"
        name: qsTr("Oldest first")
        compare: function(a, b)
        {
            return (a.date < b.date) ? 1
                                     : (a.date === b.date) ? 0
                                                           : -1;
        }
        getSection: function(item)
        {
            return Format.formatDate(item.date, Formatter.TimepointSectionRelative);
        }
    }


    property FeedSorter feedSourceLatestFirstSorter: FeedSorter {
        key: "feedLatestFirst"
        name: qsTr("Feed, then latest first")
        compare: function(a, b)
        {
            if (a.source === b.source)
            {
                return (a.date < b.date) ? -1
                                         : (a.date === b.date) ? 0
                                                               : 1;
            }
            else
            {
                return (a.name < b.name) ? 1
                                         : -1;
            }
        }
        getSection: function(item)
        {
            return item.name;
        }
    }

    property FeedSorter feedSourceOldestFirstSorter: FeedSorter {
        key: "feedOldestFirst"
        name: qsTr("Feed, then oldest first")
        compare: function(a, b)
        {
            if (a.source === b.source)
            {
                return (a.date < b.date) ? 1
                                         : (a.date === b.date) ? 0
                                                               : -1;
            }
            else
            {
                return (a.name < b.name) ? 1
                                         : -1;
            }
        }
        getSection: function(item)
        {
            return item.name;
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
            feedInfo[source].loading = false;
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
            feedInfo[source].loading = false;
            listModel.feedInfoChanged();

            _handleError(details);
            _loadNext();
        }
    }


    /* Timer for running tasks in the background.
     */
    property Timer _backgroundTimer: Timer {

        property var bgWorkers: []

        function execute(worker)
        {
            bgWorkers.push(worker);

            if (! running)
            {
                start();
            }
        }

        function abort()
        {
            bgWorkers = [];
            stop();
        }

        interval: 10
        repeat: true

        onTriggered: {
            var begin = new Date();
            var now = begin;

            while (bgWorkers.length > 0 &&
                   now.getTime() - begin.getTime() < 30 /*ms*/)
            {
                if (!bgWorkers[0]())
                {
                    bgWorkers.shift();
                    if (bgWorkers.length === 0)
                    {
                        stop();
                    }
                    break;
                }
                now = new Date();
            }
        }
    }

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
        for (var i = 0; i < feedSorters.length; ++i)
        {
            if (feedSorters[i].key === key)
            {
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

    /* Synchronizes the items with the UI. This needs to be done whenever the
     * list of items changed.
     */
    function _synchronize()
    {
        clear();
        for (var i = 0; i < _items.length; ++i)
        {
            append(_items[i]);
        }
    }

    function _hasItem(source, uid)
    {
        for (var i = 0; i < _items.length; ++i)
        {
            if (_items[i].source === source && _items[i].uid === uid)
            {
                return true;
            }
        }
        return false;
    }

    /* Inserts the given item into this model.
     */
    function _insertItem(item)
    {
        // binary search for insertion place
        function f(begin, end, comp)
        {
            if (begin === end)
            {
                if (comp(item, _items[begin]) === -1)
                {
                    _items.splice(begin + 1, 0, item);
                    //insert(begin + 1, item);
                }
                else
                {
                    _items.splice(begin, 0, item);
                    //insert(begin, item);
                }
            }
            else
            {
                var middle = begin + Math.floor((end - begin) / 2);
                if (comp(item, _items[middle]) === -1)
                {
                    f(middle + 1, end, comp);
                }
                else
                {
                    f(begin, middle, comp);
                }
            }
        }

        item["sectionTitle"] = feedSorter.getSection(item);
        if (_items.length > 0)
        {
            f(0, _items.length - 1, feedSorter.compare);
        }
        else
        {
            _items.push(item);
            //append(item);
        }
    }

    /* Adds the item from the given model.
     */
    function _loadItem(model, i)
    {
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

        if (_hasItem(item.source, item.uid))
        {
            // do not insert the same item twice
            return;
        }

        item["read"] = Database.isRead(item.source, item.uid);
        if (item.read)
        {
            // read items are gone
            return;
        }

        // don't add item if shelved, because it will be taken off the shelf
        item["shelved"] = Database.isShelved(item.source, item.uid);
        if (item.shelved)
        {
            return;
        }

        item["name"] = _feedLoader.feedName;
        item["color"] = _feedLoader.feedColor;
        item["thumbnail"] = _findThumbnail(item);
        item["enclosures"] = _getEnclosures(item);

        _insertItem(item);
        _feedInfoCountIncrement(_feedLoader.source);
        _feedInfoUnreadCountIncrement(_feedLoader.source);
    }

    /* Returns the MIME type of an enclosure.
     */
    function _enclosureType(item, i)
    {
        var url = item["enclosure_" + i + "_url"];
        var type = item["enclosure_" + i + "_type"];

        if (type)
        {
            return type;
        }
        else if (url.substring(url.length - 4).toLowerCase() === ".jpg")
        {
            return "image/jpeg";
        }
        else if (url.substring(url.length - 4).toLowerCase() === ".png")
        {
            return "image/png";
        }
        else
        {
            return "application/octet-stream";
        }
    }

    /* Returns a thumbnail URL if there is something usable, or an empty string
     * otherwise.
     */
    function _findThumbnail(item)
    {
        var i;
        var url;

        if (item.iTunesImage)
        {
            return item.iTunesImage;
        }

        var thumb = "";
        var minDelta = 9999;
        var goodWidth = 100;
        for (i = 1; i <= Math.min(item.thumbnailsAmount, 9); ++i)
        {
            url = item["thumbnail_" + i + "_url"];
            var width = item["thumbnail_" + i + "_width"];

            if (width === undefined)
            {
                width = 0;
            }

            if (Math.abs(goodWidth - width) < minDelta)
            {
                minDelta = Math.abs(goodWidth - width);
                thumb = url;
            }
        }

        if (thumb !== "")
        {
            return thumb;
        }

        for (i = 1; i <= Math.min(item.enclosuresAmount, 9); ++i)
        {
            url = item["enclosure_" + i + "_url"];
            var type = _enclosureType(item, i);

            if (type && type.substring(0, 6) === "image/")
            {
                return url;
            }
        }

        return "";
    }

    /* Returns a list of enclosure objects (url, type, length).
     */
    function _getEnclosures(item)
    {
        var enclosures = [];
        for (var i = 1; i <= Math.min(item.enclosuresAmount, 9); ++i)
        {
            var url = item["enclosure_" + i + "_url"];
            var type = _enclosureType(item, i);
            var length = item["enclosure_" + i + "_length"];

            var enclosure = {
                "url": url ? url : "",
                "type": type,
                "length" : length ? length : "-1"
            };
            console.log("enclosure " + url + " " + type + " " + length);
            enclosures.push(enclosure);
        }

        return enclosures;
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

            _feedInfoSetLoading(url, true);
            _feedInfoRefreshed(url);

            _feedLoader.feedColor = color;
            _feedLoader.feedName = name;
            _feedLoader.source = url;
        }
        else
        {
            currentlyLoading = "";
            _synchronize();
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
        _feedInfoSetLoading(_feedLoader.source, true);

        function loader()
        {
            if (index < feedModel.count)
            {
                _loadItem(feedModel, index);
                ++index;
                return true;
            }
            else
            {
                _feedInfoSetLoading(_feedLoader.source, false);
                _loadNext();
                return false;
            }
        }

        _backgroundTimer.execute(loader);
    }

    /* Rearranges the items according to the current sorter.
     */
    function _rearrangeItems()
    {
        busy = true;

        var items = [];
        for (var i = 0; i < _items.length; ++i)
        {
            items.push(_items[i]);
        }
        _items = [];

        function rearranger()
        {
            if (items.length)
            {
                _insertItem(items.shift());
                return true;
            }
            else
            {
                _synchronize();
                busy = false;
                return false;
            }
        }

        _backgroundTimer.execute(rearranger);
    }

    /* Clears and reloads the model from the current sources.
     */
    function refreshAll()
    {
        var items = [];
        for (var i = 0; i < _items.length; ++i)
        {
            if (! _items[i].read || _items[i].shelved)
            {
                items.push(_items[i]);
            }
            else
            {
                _feedInfoCountDecrement(_items[i].source);
            }

        }
        _items = items;

        for (i = 0; i < sources.length; i++)
        {
            console.log("Source: " + sources[i].url);
            _sourcesQueue.push(sources[i]);
            //_feedInfoCountReset(sources[i].url);
        }
        _loadNext();
        lastRefresh = new Date();
    }

    /* Refreshes the model from the given source.
     */
    function refresh(source)
    {
        var items = [];
        for (var i = 0; i < _items.length; ++i)
        {
            if (! _items[i].read ||
                    _items[i].shelved ||
                    _items[i].source !== source.url)
            {
                items.push(_items[i]);
            }
            else if (_items[i].source === source.url)
            {
                _feedInfoCountDecrement(source.url);
            }
        }
        _items = items;

        _sourcesQueue.push(source);
        if (! busy)
        {
            //_feedInfoCountReset(source.url);
            lastRefresh = new Date();
            _loadNext();
        }
    }

    /* Removes all items belonging to the given source, unless shelved.
     */
    function removeItems(source)
    {
        busy = true;
        var items = [];
        for (var i = 0; i < _items.length; ++i)
        {
            if (_items[i].shelved ||
                _items[i].source !== source)
            {
                items.push(_items[i]);
            }
            else if (_items[i].source === source)
            {
                _feedInfoCountDecrement(source);
            }
        }
        _items = items;
        _synchronize();
        _feedInfoUnreadCountReset(source);
        busy = false;
    }

    /* Loads the shelved items.
     */
    function loadShelved()
    {
        var items = Database.shelvedItems();
        busy = true;

        function loader()
        {
            if (items.length > 0)
            {
                var item = json.fromJson(items.shift());
                item["date"] = item.dateString !== "" ? new Date(item.dateString)
                                                      : new Date();
                item["shelved"] = true;

                if (! _hasItem(item.uid))
                {
                    _insertItem(item);
                    _feedInfoCountIncrement(item.source);
                }
                return true;
            }
            else
            {
                _synchronize();
                busy = false;
                return false;
            }
        }

        _backgroundTimer.execute(loader);
    }

    /* Aborts loading.
     */
    function abort() {
        _sourcesQueue = [];
        _backgroundTimer.abort();
        _synchronize();
        _feedInfoSetLoading(_feedLoader.source, false);
        busy = false;
    }

    /* Returns the index of the previous item of the same feed as the given
     * index, or -1 if there is none.
     */
    function previousOfFeed(idx)
    {
        var item = _items[idx];
        for (var i = idx - 1; i >= 0; --i)
        {
            if (_items[i].source === item.source)
            {
                return i;
            }
        }
        return -1;
    }

    /* Returns the index of the next item of the same feed as the given index,
     * or -1 if there is none.
     */
    function nextOfFeed(idx)
    {
        var item = _items[idx];
        for (var i = idx + 1; i < count; ++i)
        {
            if (_items[i].source === item.source)
            {
                return i;
            }
        }
        return -1;
    }

    /* Returns the index of the first item of the given feed source, or -1 if
     * there is none.
     */
    function firstOfFeed(source)
    {
        for (var i = 0; i < count; ++i)
        {
            if (_items[i].source === source)
            {
                return i;
            }
        }
        return -1;
    }

    /* Marks the given item as read.
     */
    function setRead(idx, value)
    {
        var item = get(idx);
        if (! item.read)
        {
            Database.setRead(item.source, item.uid, value);
            item.read = value;
            _items[idx].read = value;
            _feedInfoUnreadCountDecrement(item.source);
        }
    }

    /* Marks all items of the given source as read.
     */
    function setAllRead(source)
    {
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

        _backgroundTimer.execute(marker);
    }

    /* Keeps or removes the given item from the shelf.
     */
    function shelveItem(idx, value)
    {
        var item = _items[idx];

        if (value)
        {
            console.log("shelving " + item.source + " " + item.uid);
            Database.shelveItem(item.source, item.uid, json.toJson(item));
        }
        else
        {
            console.log("unshelving " + item.source + " " + item.uid);
            Database.unshelveItem(item.source, item.uid);
        }
        item.shelved = value;
        get(idx).shelved = value;
    }

    /* Returns if the given item is currently shelved.
     */
    function isShelved(idx)
    {
        var item = _items[idx];
        return Database.isShelved(item.source, item.uid);
    }

    // rearrange items if the sorter changed
    onFeedSorterChanged: {
        if (count > 0 && ! busy)
        {
            _rearrangeItems();
        }
    }

    Component.onCompleted: {
        Database.forgetRead(3600 * 24 * 90);
    }
}
