import QtQuick 2.0

QtObject {
    property string key
    property string value
    property bool booleanValue: value !== "0"
    property string _previousValue: value

    Component.onCompleted: {
        console.log("Reading config value: " + key);
        var deflt = value;
        _previousValue = database.configGet(key, deflt);
        value = _previousValue;
    }

    onValueChanged: {
        if (value !== _previousValue)
        {
            console.log("Storing config value: " + key);
            _previousValue = value;
            database.configSet(key, value);
        }
    }
}
