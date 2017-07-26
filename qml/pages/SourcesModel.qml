import QtQuick 2.0

ListModel {

    property var names: ({})
    property var colors: ({})

    signal modelChanged

    function addSource(name, url, color) {
        var sourceId = database.addSource(name, url, color);
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
        database.changeSource(sourceId, name, url, color);

        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                set (i, {
                         "sourceId": sourceId,
                         "name": name,
                         "url": url,
                         "color": color})

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
        database.removeSource(sourceId);
        for (var i = 0; i < count; i++) {
            if (get(i).sourceId === sourceId) {
                remove(i);
                break;
            }
        }

        modelChanged();
        namesChanged();
        countChanged();
        colorsChanged();
    }

    function forgetSourceRead(sourceId)
    {
        database.forgetSourceRead(sourceId);
    }

    function moveItem(from, to)
    {
        move(from, to, 1);

        modelChanged();
        countChanged();
        namesChanged();
        colorsChanged();
    }

    function savePositions()
    {
        console.log("Saving feed positions");
        var sourceIds = [];
        for (var i = 0; i < count; i++)
        {
            sourceIds.push(get(i).sourceId);
        }
        database.setPositions(sourceIds);
    }

    Component.onCompleted: {
        console.log("Setting up feeds");
        var items = database.sources();

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
