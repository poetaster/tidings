import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0
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
    property bool busy

    // name of the feed currently loading
    property string currentlyLoading

    property RssModel _rssModel: RssModel {
        onStatusChanged: {
            console.log("RssModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _load();
            } else if (status !== XmlListModel.Loading) {
                _addItems(_rssModel);
                if (count === 0) {
                    _atomModel.name = name;
                    _atomModel.source = "";
                    _atomModel.source = source;
                    _atomModel.color = color;
                } else {
                    _load();
                }
            }
        }
    }

    property AtomModel _atomModel: AtomModel {
        onStatusChanged: {
            console.log("AtomModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _load();
            } else if (status !== XmlListModel.Loading) {
                _addItems(_atomModel);
                if (count === 0) {
                    _opmlModel.name = name;
                    _opmlModel.source = "";
                    _opmlModel.source = source;
                    _opmlModel.color = color;
                } else {
                    _load();
                }
            }

        }
    }

    property OpmlModel _opmlModel: OpmlModel {
        onStatusChanged: {
            console.log("OpmlModel.status = " + status + " (" + source + ")");
            if (status === XmlListModel.Error) {
                _handleError(errorString());
                _load();
            } else if (status !== XmlListModel.Loading) {
                _addItems(_opmlModel);
                _load();
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
    function _insertItem(item) {

        function f(begin, end) {
            if (begin === end) {
                if (item.date < get(begin).date) {
                    insert(begin + 1, item);
                } else {
                    insert(begin, item);
                }
            } else {
                var middle = begin + Math.floor((end - begin) / 2);
                if (item.date < get(middle).date) {
                    f(middle + 1, end);
                } else {
                    f(begin, middle);
                }
            }
        }
        if (count > 0) {
            f(0, count - 1);
        } else {
            append(item);
        }
    }

    /* Adds the item from the given model.
     */
    function _addItems(model) {
        if (model.status === XmlListModel.Ready) {
            for (var i = 0; i < model.count; i++) {
                var item = model.get(i);
                item["source"] = "" + model.source; // convert to string
                item["date"] = item.dateString !== "" ? new Date(item.dateString)
                                                      : new Date();
                if (item.uid === "") {
                    // if there is no UID, make a unique one
                    if (item.dateString !== "") {
                        item["uid"] = item.title + item.dateString;
                    } else {
                        var d = new Date();
                        item["uid"] = item.title + d.getTime();
                    }
                }

                item["read"] = Database.isRead(item.source, item.uid);
                if (item.read) {
                    // read items are gone
                    continue;
                }

                item["name"] = model.name;
                item["color"] = model.color;
                item["sectionDate"] = Format.formatDate(item.date, Formatter.TimepointSectionRelative);
                item["thumbnail"] = _findThumbnail(item);
                item["enclosures"] = _getEnclosures(item);

                _insertItem(item);
            }
        }
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
    function _load() {
        for (var i = 0; i < _models.length; i++) {
            if (_models[i].status === XmlListModel.Loading) {
                return;
            }
        }

        var queue = _sourcesQueue;
        if (queue.length > 0) {
            var source = queue.pop();
            var url = source.url;
            var name = source.name;
            var color = source.color;

            currentlyLoading = name;
            _rssModel.name = name;
            _rssModel.source = "";
            _rssModel.source = url;
            _rssModel.color = color;

            _sourcesQueue = queue;
        }
        else
        {
            busy = false;
            currentlyLoading = "";
        }
    }

    /* Handles errors.
     */
    function _handleError(error) {
        console.log(error);
        var feedName = currentlyLoading;
        if (error.substring(0, 5) === "Host ") {
            // Host ... not found
            /*
            for (var i = 0; i < _models.length; i++) {
                if (_models[i].status === XmlListModel.Loading) {
                    _models[i].source = "";
                }
            }
            */
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
        _load();
        lastRefresh = new Date();
    }

    /* Aborts loading.
     */
    function abort() {
        _sourcesQueue = [];
        for (var i = 0; i < _models.length; i++) {
            _models[i].source = "";
        }
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

    Component.onCompleted: {
        Database.forgetRead(3600 * 24 * 90);
    }
}
