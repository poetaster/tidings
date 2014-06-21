import QtQuick 2.0
import "database.js" as Database

ListModel {

    signal modelChanged

    function addSource(name, url, color) {
        var sourceId = Database.addSource(name, url, color);
        append({
                   "sourceId": sourceId,
                   "name": name,
                   "url": url,
                   "color": color
               });

        modelChanged();
    }

    function changeSource(sourceId, name, url, color) {
        Database.changeSource(sourceId, name, url, color);
        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                get(i).name = name;
                get(i).url = url;
                get(i).color = color;
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

    function forgetSourceRead(sourceId)
    {
        Database.forgetSourceRead(sourceId);
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
