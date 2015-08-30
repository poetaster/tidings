import QtQuick 2.0
import "database.js" as Database

ListModel {

    property var names: ({})
    property var colors: ({})

    signal modelChanged

    function addSource(name, url, color) {
        var sourceId = Database.addSource(name, url, color);
        append({
                   "sourceId": sourceId,
                   "name": name,
                   "url": url,
                   "color": color
               });
        names[url] = name;
        colors[url] = color;

        modelChanged();
        namesChanged();
        colorsChanged();
    }

    function changeSource(sourceId, name, url, color) {
        Database.changeSource(sourceId, name, url, color);
        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                get(i).name = name;
                get(i).url = url;
                get(i).color = color;

                names[url] = name;
                colors[url] = color;

                break;
            }
        }

        modelChanged();
        namesChanged();
        colorsChanged();
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
        namesChanged();
        colorsChanged();
    }

    function forgetSourceRead(sourceId)
    {
        Database.forgetSourceRead(sourceId);
    }

    function moveItem(from, to)
    {
        move(from, to, 1);

        modelChanged();
        countChanged();
        namesChanged();
        colorsChanged();
    }

    Component.onCompleted: {
        var items = Database.sources();

        for (var i = 0; i < items.length; i++) {
            console.log(items[i].sourceId + " " + items[i].name);
            append(items[i]);
            names[items[i].url] = items[i].name;
            colors[items[i].url] = items[i].color;
        }

        modelChanged();
        namesChanged();
        colorsChanged();
    }
}
