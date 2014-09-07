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

    function setTotalCounts(counts)
    {
        var keys = Object.keys(counts);
        console.log("total counts " + keys.length);
        for (var i = 0; i < keys.length; ++i)
        {
            var feedSource = keys[i];
            _ensureItem(feedSource);
            stats[feedSource].count = counts[feedSource];
        }
    }

    function setUnreadCounts(counts)
    {
        var keys = Object.keys(counts);
        console.log("unread counts " + keys.length);
        for (var i = 0; i < keys.length; ++i)
        {
            var feedSource = keys[i];
            _ensureItem(feedSource);
            stats[feedSource].unreadCount = counts[feedSource];
        }
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
