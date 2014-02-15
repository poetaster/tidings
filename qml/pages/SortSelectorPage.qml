import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    SilicaListView {
        id: listview

        anchors.fill: parent
        model: newsBlendModel.feedSorters

        header: PageHeader {
            title: "Sort by"
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
                newsBlendModel.feedSorter = modelData;
                pageStack.pop();
            }
        }
    }
}
