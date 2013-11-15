import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    property Item _contextMenu
    property Item _contextMenuItem

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

        delegate: Item {
            id: listItem

            property int sourceId: model.sourceId
            property string name: model.name
            property string url: model.url

            property bool menuOpen: _contextMenu != null
                                    && _contextMenu.parent === listItem

            function remove() {
                remorse.execute(listItem, qsTr("Deleting"),
                                function() { sourcesModel.removeSource(sourceId); } )
            }

            width: listview.width
            height: menuOpen ? _contextMenu.height + contentItem.height
                             : contentItem.height

            RemorseItem { id: remorse }

            ListItem {
                id: contentItem

                height: Theme.itemSizeMedium

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

                onPressAndHold: {
                    if (! _contextMenu) {
                        _contextMenu = contextMenuComponent.createObject(listview);
                    }
                    _contextMenuItem = listItem;
                    _contextMenu.show(listItem);
                }

                onClicked: {
                    var props = {
                        "name": listItem.name,
                        "url": listItem.url,
                        "sourceId": listItem.sourceId,
                        "editOnly": true
                    }
                    pageStack.push("SourceEditDialog.qml", props);
                }
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
            MenuItem {
                text: qsTr("Remove")
                onClicked: {
                    _contextMenuItem.remove();
                }
            }
        }
    }
}
