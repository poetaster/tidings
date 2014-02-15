import QtQuick 2.0

QtObject {

    property string name: "by example"

    property var compare: function(a, b)
    {
        return 1;
    }

    property var getSection: function(item)
    {
        return "";
    }

}
