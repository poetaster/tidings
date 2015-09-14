import QtQuick 2.0

Loader {
    property string parserUrl
    property int parserStatus

    property string xml

    function errorString()
    {
        return item ? item.errorString() : "";
    }

    onXmlChanged: {
        if (! item)
        {
            console.log("Loading parser: " + parserUrl);
            source = parserUrl;
            item.statusChanged.connect(function() { parserStatus = item.status; })
        }
        item.xml = "";
        item.xml = xml;
    }
}
