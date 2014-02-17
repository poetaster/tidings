import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    property var _callback

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
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                color: listitem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            onClicked: {
                function closure(sorter)
                {
                    return function()
                    {
                        newsBlendModel.feedSorter = sorter;
                    }
                }

                _callback = closure(modelData);
                pageStack.pop();
            }
        }
    }
}
