import QtQuick 2.0

QtObject {

    property var stats: ({ })

    function _ensureItem(key)
    {
        if (! stats[key])
        {
            var item = _statsComponent.createObject(null);
            stats[key] = item;
        }
    }

    function reset(key)
    {
        _ensureItem(key);
        stats[key].unreadCount = 0;
        stats[key].count = 0;
        statsChanged();
    }

    function increment(key)
    {
        _ensureItem(key);
        stats[key].count += 1;
        statsChanged();
    }

    function incrementUnread(key)
    {
        _ensureItem(key);
        stats[key].unreadCount += 1;
        statsChanged();
    }

    function decrementUnread(key)
    {
        _ensureItem(key);
        stats[key].unreadCount -= 1;
        statsChanged();
    }

    function setLoading(key, value)
    {
        _ensureItem(key);
        stats[key].loading = value;
        statsChanged();
    }

    function setRefreshed(key)
    {
        _ensureItem(key);
        stats[key].lastRefresh = new Date();
        statsChanged();
    }

    property Component _statsComponent: Component {
        QtObject {
            property date lastRefresh
            property bool loading
            property int count
            property int unreadCount
        }
    }
}
