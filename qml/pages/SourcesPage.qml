import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    SilicaListView {
        id: listview

        model: sourcesModel

        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Sources")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Source ...")

                onClicked: {
                    pageStack.push("SourceEditDialog.qml", {});
                }
            }
        }

        delegate: ListItem {
            id: listItem

            property int sourceId: model.sourceId
            property string name: model.name
            property string url: model.url
            property string color: model.color

            function remove() {
                remorseAction(qsTr("Deleting"),
                              function() { sourcesModel.removeSource(sourceId); });
            }

            width: listview.width
            menu: contextMenuComponent

            Rectangle {
                width: 2
                height: parent.height
                color: model.color
            }

            Label {
                id: nameLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium
                color: Theme.primaryColor
                elide: Text.ElideRight
                text: name
            }

            Label {
                anchors.top: nameLabel.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.rightMargin: Theme.paddingMedium
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                elide: Text.ElideRight
                text: url
            }

            onClicked: {
                var props = {
                    "name": listItem.name,
                    "url": listItem.url,
                    "color": listItem.color,
                    "sourceId": listItem.sourceId,
                    "editOnly": true
                }
                pageStack.push("SourceEditDialog.qml", props);
            }
        }

        ViewPlaceholder {
            enabled: listview.count === 0
            text: qsTr("Pull down to add RSS, Atom, or OPML sources.")
        }

        ScrollDecorator { }

    }

    Component {
        id: contextMenuComponent
        ContextMenu {
            id: menu
            MenuItem {
                text: qsTr("Remove")

                onClicked: {
                    menu.parent.remove();
                }
            }
        }
    }
}
