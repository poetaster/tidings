import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import Sailfish.Silica 1.0

/* List model that blends various feed models together.
 */
ListModel {
    id: listModel

    // The list of all feed sources to load.
    property variant sources: []

    property AtomModel _atomModel: AtomModel {
        onStatusChanged: {
            if (status !== XmlListModel.Loading) {
                _addItems(_atomModel);
                _load();
            }
        }
    }

    property OpmlModel _opmlModel: OpmlModel {
        onStatusChanged: {
            if (status !== XmlListModel.Loading) {
                _addItems(_opmlModel);
                _load();
            }
        }
    }

    property RssModel _rssModel: RssModel {
        onStatusChanged: {
            if (status !== XmlListModel.Loading) {
                _addItems(_rssModel);
                _load();
            }
        }
    }

    property variant _models: [
        _atomModel, _opmlModel, _rssModel
    ]

    property variant _sourcesQueue: []

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
                item["name"] = model.name;
                item["date"] = item.dateString !== "" ? new Date(item.dateString)
                                                      : new Date();
                item["sectionDate"] = Format.formatDate(item.date, Formatter.TimepointSectionRelative);
                _insertItem(item);
            }
        }
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

            for (var i = 0; i < _models.length; i++) {
                _models[i].name = name;
                _models[i].source = url;
            }

            _sourcesQueue = queue;
        }
    }

    /* Clears and reloads the model from the current sources.
     */
    function refresh() {
        console.log("Refreshing model");
        clear();
        for (var i = 0; i < sources.length; i++) {
            console.log("Source: " + sources[i].url);
        }
        _sourcesQueue = sources;
        _load();
    }
}
