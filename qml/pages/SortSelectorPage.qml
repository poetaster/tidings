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
            width: listview.width

            Label {
                text: modelData.name
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            onClicked: {
                newsBlendModel.feedSorter = modelData;
                pageStack.pop();
            }
        }
    }
}
