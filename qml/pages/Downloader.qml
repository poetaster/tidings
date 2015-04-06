import QtQuick 2.0
import harbour.tidings 1.0

UrlLoader {

    property var _queue: []

    function downloadToGallery(url, name)
    {
        _queue.push([url, name]);
        if (! loading)
        {
            _next();
        }
    }

    function _next()
    {
        if (_queue.length > 0)
        {
            var item = _queue.shift()
            source = item[0];
            destination = galleryPath(item[1]);
        }
    }

    onLoadingChanged: {
        if (! loading)
        {
            _next();
        }
    }

}
