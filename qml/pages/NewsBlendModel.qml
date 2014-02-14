import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0
import "database.js" as Database

/* List model that blends various feed models together.
 */
ListModel {
    id: listModel

    // the list of all feed sources to load.
    property variant sources: []

    // the time of the last refresh
    property variant lastRefresh

    // flag indicating that this model is busy
    property bool busy: false

    // name of the feed currently loading
    property string currentlyLoading

    property FeedLoader _feedLoader: FeedLoader {
        property string feedName
        property string feedColor

        onSuccess: {
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
            _handleError(details);
            _loadNext();
        }
    }

    property Timer _itemLoader: Timer {
        property variant model
        property int index

        function load(loadModel)
        {
            model = loadModel;
            index = 0;
            start();
        }

        interval: 75
        repeat: true

        onTriggered: {
            for (var end = index + 2;
                 index < end && index < model.count;
                 index++)
            {
                listModel._loadItem(model, index);
                index++;
            }
            if (index >= model.count)
            {
                stop();
                _loadNext();
            }
        }
    }

    property RssModel _rssModel: RssModel {
        onStatusChanged: {
            console.log("RssModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _loadNext();
            } else if (status === XmlListModel.Ready) {
                _itemLoader.load(_rssModel);
            }
        }
    }

    property RssModel _rdfModel: RdfModel {
        onStatusChanged: {
            console.log("RdfModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _loadNext();
            } else if (status === XmlListModel.Ready) {
                _itemLoader.load(_rdfModel);
            }
        }
    }

    property AtomModel _atomModel: AtomModel {
        onStatusChanged: {
            console.log("AtomModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _loadNext();
            } else if (status === XmlListModel.Ready) {
                _itemLoader.load(_atomModel);
            }
        }
    }

    property OpmlModel _opmlModel: OpmlModel {
        onStatusChanged: {
            console.log("OpmlModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _loadNext();
            } else if (status === XmlListModel.Ready) {
                _addItems(_opmlModel);
                _itemLoader.load(_opmlModel);
            }
        }
    }

    property variant _models: [
        _atomModel, _opmlModel, _rssModel
    ]

    property variant _sourcesQueue: []

    signal error(string details)

    /* Inserts the given item into this model.
     */
    function _insertItem(item)
    {

        function f(begin, end)
        {
            if (begin === end)
            {
                if (item.date < get(begin).date)
                {
                    insert(begin + 1, item);
                }
                else
                {
                    insert(begin, item);
                }
            }
            else
            {
                var middle = begin + Math.floor((end - begin) / 2);
                if (item.date < get(middle).date)
                {
                    f(middle + 1, end);
                }
                else
                {
                    f(begin, middle);
                }
            }
        }
        if (count > 0)
        {
            f(0, count - 1);
        }
        else
        {
            append(item);
        }
    }

    /* Adds the item from the given model.
     */
    function _loadItem(model, i)
    {
        var item = model.get(i);
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
        item["sectionDate"] = Format.formatDate(item.date, Formatter.TimepointSectionRelative);
        item["thumbnail"] = _findThumbnail(item);
        item["enclosures"] = _getEnclosures(item);

        _insertItem(item);
    }

    /* Returns a thumbnail URL if there is something usable, or an empty string
     * otherwise.
     */
    function _findThumbnail(item) {
        var i;
        var url;

        if (item.iTunesImage) {
            return item.iTunesImage;
        }

        var thumb = "";
        var minDelta = 9999;
        var goodWidth = 100;
        for (i = 1; i <= Math.min(item.thumbnailsAmount, 9); ++i) {
            url = item["thumbnail_" + i + "_url"];
            var width = item["thumbnail_" + i + "_width"];

            if (width === undefined) {
                width = 0;
            }

            if (Math.abs(goodWidth - width) < minDelta) {
                minDelta = Math.abs(goodWidth - width);
                thumb = url;
            }
        }

        if (thumb !== "") {
            return thumb;
        }

        for (i = 1; i <= Math.min(item.enclosuresAmount, 9); ++i) {
            url = item["enclosure_" + i + "_url"];
            var type = item["enclosure_" + i + "_type"];

            if (type && type.substring(0, 6) === "image/") {
                return url;
            }
        }

        return "";
    }

    /* Returns a list of enclosure objects (url, type, length).
     */
    function _getEnclosures(item) {
        var enclosures = [];
        for (var i = 1; i <= Math.min(item.enclosuresAmount, 9); ++i) {
            var url = item["enclosure_" + i + "_url"];
            var type = item["enclosure_" + i + "_type"];
            var length = item["enclosure_" + i + "_length"];

            var enclosure = {
                "url": url ? url : "",
                "type": type ? type : "application/octet-stream",
                "length" : length ? length : "-1"
            };
            console.log("enclosure " + url + " " + type + " " + length);
            enclosures.push(enclosure);
        }

        return enclosures;
    }

    /* Takes the next source from the sources queue and loads it.
     */
    function _loadNext() {
        var queue = _sourcesQueue;
        if (queue.length > 0) {
            var source = queue.pop();
            var url = source.url;
            var name = source.name;
            var color = source.color;

            console.log("Now loading: " + name);
            currentlyLoading = name;
            _feedLoader.feedColor = color;
            _feedLoader.feedName = name;
            _feedLoader.source = url;

            _sourcesQueue = queue;
        }
        else
        {
            // add shelved items
            var shelvedItems = Database.shelvedItems();
            for (var i = 0; i < shelvedItems.length; ++i)
            {
                var item = json.fromJson(shelvedItems[i]);
                item["date"] = item.dateString !== "" ? new Date(item.dateString)
                                                      : new Date();
                item["shelved"] = true;
                _insertItem(item);
            }

            busy = false;
            currentlyLoading = "";
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

    /* Clears and reloads the model from the current sources.
     */
    function refresh() {
        console.log("Refreshing model");
        busy = true;
        clear();
        for (var i = 0; i < sources.length; i++) {
            console.log("Source: " + sources[i].url);
        }
        _sourcesQueue = sources;
        _loadNext();
        lastRefresh = new Date();
    }

    /* Aborts loading.
     */
    function abort() {
        _sourcesQueue = [];
        _itemLoader.stop();
        /*
        for (var i = 0; i < _models.length; i++) {
            _models[i].source = "";
        }
        */
        busy = false;
    }

    /* Returns the index of the previous item of the same feed as the given
     * index, or -1 if there is none.
     */
    function previousOfFeed(idx)
    {
        var item = get(idx);
        for (var i = idx - 1; i >= 0; --i)
        {
            if (get(i).source === item.source)
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
        var item = get(idx);
        for (var i = idx + 1; i < count; ++i)
        {
            if (get(i).source === item.source)
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
        Database.setRead(item.source, item.uid, value);
        item.read = value;
    }

    /* Keeps or removes the given item from the shelf.
     */
    function shelveItem(idx, value)
    {
        var item = get(idx);

        if (value)
        {
            var v = {};
            for (var key in item)
            {
                v[key] = item[key];
            }
            console.log("shelving " + item.source + " " + item.uid);
            Database.shelveItem(item.source, item.uid, json.toJson(v));
            // becomes unread
            setRead(idx, false);
        }
        else
        {
            console.log("unshelving " + item.source + " " + item.uid);
            Database.unshelveItem(item.source, item.uid);
        }
        item.shelved = value;
    }

    /* Returns if the given item is currently shelved.
     */
    function isShelved(idx)
    {
        var item = get(idx);
        return Database.isShelved(item.source, item.uid);
    }

    Component.onCompleted: {
        Database.forgetRead(3600 * 24 * 90);
    }
}
