import QtQuick 2.0
import "database.js" as Database

ListModel {

    signal modelChanged

    function addSource(name, url) {
        var sourceId = Database.addSource(name, url);
        append({
                   "sourceId": sourceId,
                   "name": name,
                   "url": url
               });

        modelChanged();
    }

    function changeSource(sourceId, name, url) {
        Database.changeSource(sourceId, name, url);
        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                get(i).name = name;
                get(i).url = url;
                break;
            }
        }

        modelChanged();
    }

    function removeSource(sourceId) {
        Database.removeSource(sourceId);
        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                remove(i);
                break;
            }
        }

        modelChanged();
    }

    Component.onCompleted: {
        var items = Database.sources();

        for (var i = 0; i < items.length; i++) {
            console.log(items[i].sourceId + " " + items[i].name);
            append(items[i]);
        }

        modelChanged();
    }

}
