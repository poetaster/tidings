import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    property var _callback

    allowedOrientations: Orientation.All

    Component.onDestruction: {
        if (_callback)
        {
            _callback();
        }
    }

    SilicaListView {
        id: listview

        anchors.fill: parent
        model: newsBlendModel.feedSorters

        header: PageHeader {
            title: qsTr("Sort by")
        }

        delegate: ListItem {
            id: listitem

            width: listview.width

            Label {
                text: modelData.name
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                color: listitem.highlighted ? Theme.highlightColor : Theme.primaryColor
                wrapMode: Text.Wrap
            }

            onClicked: {
                function closure(sorter)
                {
                    return function()
                    {
                        configFeedSorter.value = sorter.key;
                    }
                }

                _callback = closure(modelData);
                pageStack.pop();
            }
        }
    }
}
