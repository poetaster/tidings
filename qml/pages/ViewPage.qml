import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "ViewPage"

    property ListView listview
    property variant itemData: listview.currentItem !== null
                               ? listview.currentItem.data
                               : null

    property Page _attachedWebView

    property int _currentIndex: listview.currentIndex
    property int _previousOfFeed: -1
    property int _nextOfFeed: -1

    function previousItem() {
        listview.currentIndex = listview.currentIndex - 1;
    }

    function nextItem() {
        listview.currentIndex = listview.currentIndex + 1;
    }

    function goToItem(idx) {
        listview.currentIndex = idx;
    }

    /* Returns the filename of the given URL.
     */
    function _urlFilename(url) {
        var idx = url.lastIndexOf("=");
        if (idx !== -1) {
            return url.substring(idx + 1);
        }

        idx = url.lastIndexOf("/");
        if (idx === url.length - 1) {
            idx = url.substring(0, idx).lastIndexOf("/");
        }

        if (idx !== -1) {
            return url.substring(idx + 1);
        }

        return url;
    }

    /* Returns the icon source for the given media.
     */
    function _mediaIcon(url, type) {
        if (type.substring(0, 6) === "audio/") {
            return "image://theme/icon-m-media";
        } else if (type.substring(0, 6) === "image/") {
            return url;
        } else {
            return "image://theme/icon-m-other";
        }
    }

    /* Returns a user-friendly media type name for the given MIME type.
     */
    function _mediaTypeName(type) {
        if (type.substring(0, 6) === "audio/") {
            return qsTr("Audio");
        } else if (type.substring(0, 6) === "image/") {
            return qsTr("Image");
        } else if (type.substring(0, 6) === "video/") {
            return qsTr("Video");
        } else if (type === "application/pdf") {
            return qsTr("PDF document");
        } else {
            return type;
        }
    }

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    Component.onCompleted: {
        navigationState.openedItem(listview.currentIndex);
        if (! itemData.read && ! itemData.shelved) {
            newsBlendModel.setRead(listview.currentIndex, true);
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && itemData.link !== "")
        {
            var props = {
                "url": itemData.link
            }
            _attachedWebView = pageStack.pushAttached(Qt.resolvedUrl("WebPage.qml"), props);
        }
    }

    onItemDataChanged: {
        if (itemData)
        {
            if (_attachedWebView)
            {
                _attachedWebView.url = itemData.link;
            }

            navigationState.openedItem(listview.currentIndex);
            if (! itemData.read && ! itemData.shelved) {
                newsBlendModel.setRead(listview.currentIndex, true);
            }
        }
    }

    on_CurrentIndexChanged: {
        _previousOfFeed = newsBlendModel.previousOfFeed(listview.currentIndex);
        _nextOfFeed = newsBlendModel.nextOfFeed(listview.currentIndex);

    }

    ConfigValue {
        id: configTintedBackground
        key: "feed-background-tinted"
        value: "0"
    }

    Connections {
        target: coverAdaptor

        onPreviousItem: {
            previousItem();
        }

        onNextItem: {
            nextItem();
        }
    }

    Rectangle {
        visible: configTintedBackground.booleanValue
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.7)
    }

    Rectangle {
        width: 2
        height: parent.height
        color: feedColor[itemData.source]
    }

    SilicaFlickable {
        id: contentFlickable

        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            id: pulleyDown

            property var _closeAction

            onActiveChanged: {
                if (! active && _closeAction)
                {
                    _closeAction();
                    _closeAction = null;
                }
            }

            MenuItem {
                text: qsTr("Toggle background")

                onClicked: {
                    configTintedBackground.value = configTintedBackground.booleanValue ? "0" : "1";
                }
            }

            MenuItem {
                enabled: _previousOfFeed !== -1
                text: "<" + feedName[itemData.source] + ">"

                onClicked: {
                    function f()
                    {
                        goToItem(_previousOfFeed);
                        contentFlickable.contentY = 0;
                        column.opacity = 1;
                    }
                    pulleyDown._closeAction = f;
                    column.opacity = 0;
                }
            }
            MenuItem {
                enabled: listview.currentIndex > 0
                text: enabled ? qsTr("Previous")
                              : qsTr("Already at the beginning")

                onClicked: {
                    function f()
                    {
                        goToItem(listview.currentIndex - 1);
                        contentFlickable.contentY = 0;
                        column.opacity = 1;
                    }
                    pulleyDown._closeAction = f;
                    column.opacity = 0;
                }
            }
        }

        PushUpMenu {
            id: pulleyUp

            property var _closeAction

            onActiveChanged: {
                if (! active && _closeAction)
                {
                    _closeAction();
                    _closeAction = null;
                }
            }

            MenuItem {
                enabled: listview.currentIndex < listview.count - 1
                text: enabled ? qsTr("Next")
                              : qsTr("Already at the end")

                onClicked: {
                    function f()
                    {
                        goToItem(listview.currentIndex + 1);
                        contentFlickable.contentY = 0;
                        column.opacity = 1;
                    }
                    pulleyUp._closeAction = f;
                    column.opacity = 0;
                }
            }
            MenuItem {
                enabled: _nextOfFeed !== -1
                text: "<" + feedName[itemData.source] + ">"

                onClicked: {
                    function f()
                    {
                        goToItem(_nextOfFeed);
                        contentFlickable.contentY = 0;
                        column.opacity = 1;
                    }
                    pulleyUp._closeAction = f;
                    column.opacity = 0;
                }
            }
        }

        Column {
            id: column

            width: parent.width
            height: childrenRect.height

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            PageHeader {
                id: pageHeader
                title: feedName[itemData.source]
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                height: childrenRect.height

                Label {
                    anchors.left: parent.left
                    anchors.right: shelveIcon.left
                    anchors.rightMargin: Theme.paddingMedium
                    horizontalAlignment: Text.AlignLeft
                    color: configTintedBackground.booleanValue ? "#606060" : Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    textFormat: Text.RichText
                    text: itemData.title

                    MouseArea {
                        enabled: itemData.link !== ""
                        anchors.fill: parent
                        onClicked: {
                            var props = {
                                "url": itemData.link
                            }
                            pageStack.push(Qt.resolvedUrl("ExternalLinkDialog.qml"),
                                           props);
                        }
                    }
                }

                Image {
                    id: shelveIcon
                    anchors.right: parent.right
                    source: itemData.shelved ? "image://theme/icon-l-favorite"
                                             : "image://theme/icon-l-star"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            newsBlendModel.setShelved(listview.currentIndex, ! itemData.shelved);
                            itemData.shelved = ! itemData.shelved;
                        }
                    }
                }
            }

            Label {
                visible: itemData.mediaDuration > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignLeft
                color: configTintedBackground.booleanValue ? "#606060" : Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("(%1 seconds)").arg(itemData.mediaDuration)
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignLeft
                color: configTintedBackground.booleanValue ? "#606060" : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: Format.formatDate(itemData.date, Formatter.Timepoint)
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            RescalingRichText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                color: configTintedBackground.booleanValue ? "black" : Theme.primaryColor
                fontSize: Theme.fontSizeSmall
                text: newsBlendModel.itemBody(itemData.source, itemData.uid) // itemData.body

                onLinkActivated: {
                    var props = {
                        "url": link
                    }
                    pageStack.push(Qt.resolvedUrl("ExternalLinkDialog.qml"),
                                                  props);
                }

            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            SectionHeader {
                visible: enclosureRepeater.count > 0
                text: qsTr("Media")
            }

            Repeater {
                id: enclosureRepeater
                model: itemData.enclosures

                delegate: ListItem {
                    width: column.width

                    Image {
                        id: mediaIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        width: height
                        height: parent.height
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        source: enclosureRepeater.count ? _mediaIcon(modelData.url, modelData.type) : ""
                        clip: true
                    }

                    Label {
                        id: mediaNameLabel
                        anchors.left: mediaIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.rightMargin: Theme.paddingLarge
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        text: _urlFilename(modelData.url)
                    }
                    Label {
                        anchors.top: mediaNameLabel.bottom
                        anchors.left: mediaNameLabel.left
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: _mediaTypeName(modelData.type)
                    }
                    Label {
                        anchors.top: mediaNameLabel.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: modelData.length >= 0 ? Format.formatFileSize(modelData.length)
                                                    : ""
                    }

                    onClicked: {
                        Qt.openUrlExternally(modelData.url);
                    }
                }//ListItem
            }//Repeater

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        ScrollDecorator { }
    }

}
