import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

Page {
    id: page
    objectName: "ViewPage"

    property GridView listview
    property variant itemData: listview.currentItem !== null
                               ? listview.currentItem.data
                               : null

    property int _currentIndex: listview.currentIndex
    property int _previousOfFeed: -1
    property int _nextOfFeed: -1

    property bool _activated

    property real _pageMargin: (width > height) ? Theme.paddingLarge * 2
                                                : Theme.paddingLarge

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

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        navigationState.openedItem(listview.currentIndex);
        if (! itemData.read && ! itemData.shelved) {
            newsBlendModel.setRead(listview.currentIndex, true);
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active)
        {
            if (itemData.link !== "")
            {
                var props = {
                    "resources": resources
                };

                pageStack.pushAttached(Qt.resolvedUrl("ResourcesPage.qml"),
                                       props);
            }

            page._activated = true;
        }
    }

    onItemDataChanged: {
        if (itemData)
        {
            navigationState.openedItem(listview.currentIndex);
            if (! itemData.read && ! itemData.shelved) {
                newsBlendModel.setRead(listview.currentIndex, true);
            }

            urlLoader.source = "";
            htmlFilter.imageProxy = configLoadImages.booleanValue
                    ? ""
                    : imagePlaceholder;
        }
    }

    on_CurrentIndexChanged: {
        _previousOfFeed = newsBlendModel.previousOfFeed(listview.currentIndex);
        _nextOfFeed = newsBlendModel.nextOfFeed(listview.currentIndex);

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

    QtObject {
        id: resources
        property string link: itemData ? itemData.link : ""
        property variant images: htmlFilter.images
    }

    QtObject {
        id: contentProvider
        property string data: urlLoader.source != "" ? urlLoader.data
                                                     : itemData ? newsBlendModel.itemBody(itemData.source, itemData.uid)
                                                                : ""
    }

    UrlLoader {
        id: urlLoader
    }

    HtmlFilter {
        id: htmlFilter
        baseUrl: itemData ? itemData.source : ""
        imageProxy: configLoadImages.booleanValue ? "" :  imagePlaceholder
        html: contentProvider.data
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

            LoadImagesButton {
                visible: htmlFilter.imageProxy !== "" &&
                         htmlFilter.images.length > 0
                width: parent.width

                onClicked: {
                    htmlFilter.imageProxy = "";
                }
            }

            PageHeader {
                id: pageHeader
                title: feedName[itemData.source]
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: _pageMargin
                anchors.rightMargin: _pageMargin
                height: childrenRect.height

                Label {
                    anchors.left: parent.left
                    anchors.right: copyIcon.left
                    anchors.rightMargin: Theme.paddingMedium
                    horizontalAlignment: Text.AlignLeft
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall * (configFontScale.value / 100.0)
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
                    width: Theme.itemSizeSmall
                    height: width

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            shelveTimer.itemIndex = listview.currentIndex;
                            shelveTimer.shelved = ! itemData.shelved;
                            //newsBlendModel.setShelved(listview.currentIndex, ! itemData.shelved);
                            itemData.shelved = ! itemData.shelved;
                            shelveTimer.start();
                        }
                    }

                    Timer {
                        id: shelveTimer
                        interval: 10

                        property int itemIndex
                        property bool shelved

                        onTriggered: {
                            newsBlendModel.setShelved(itemIndex, shelved);
                        }
                    }
                }

                IconButton {
                    id: copyIcon
                    anchors.right: shelveIcon.left
                    icon.source: "image://theme/icon-m-clipboard"

                    width: Theme.itemSizeSmall
                    height: width

                    onClicked: Clipboard.text = itemData.link
                }
            }


            Label {
                visible: itemData.mediaDuration > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: _pageMargin
                anchors.rightMargin: _pageMargin
                horizontalAlignment: Text.AlignLeft
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall * (configFontScale.value / 100.0)
                text: qsTr("(%1 seconds)").arg(itemData.mediaDuration)
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: _pageMargin
                anchors.rightMargin: _pageMargin
                horizontalAlignment: Text.AlignLeft
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall * (configFontScale.value / 100.0)
                text: Format.formatDate(itemData.date, Formatter.Timepoint)
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            RescalingRichText {
                id: body

                active: page.status === PageStatus.Active

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: _pageMargin
                anchors.rightMargin: _pageMargin

                color: Theme.primaryColor
                fontSize: Theme.fontSizeSmall * (configFontScale.value / 100.0)
                text: htmlFilter.htmlFiltered

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

            Row {
                visible: ! urlLoader.loading &&
                         ! htmlFilter.busy &&
                         itemData &&
                         itemData.link !== ""
                width: column.width
                height: Theme.itemSizeLarge

                ListItem {
                    id: fullArticleButton
                    width: parent.width / 2
                    contentHeight: parent.height

                    property bool _isFull: urlLoader.source != ""

                    Image {
                        id: fullArticleIcon
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: _pageMargin
                        source: fullArticleButton._isFull ? "image://theme/icon-m-up"
                                                          : "image://theme/icon-m-down"
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: fullArticleIcon.right
                        anchors.leftMargin: Theme.paddingMedium
                        text: fullArticleButton._isFull ? qsTr("Short article")
                                                        : qsTr("Full article")
                    }

                    onClicked: {
                        if (_isFull)
                        {
                            urlLoader.source = "";
                        }
                        else
                        {
                            urlLoader.source = itemData.link;
                        }
                    }
                }

                ListItem {
                    width: parent.width / 2
                    contentHeight: parent.height

                    Image {
                        id: webIcon
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: _pageMargin
                        source: "image://theme/icon-m-region"
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: webIcon.right
                        anchors.leftMargin: Theme.paddingMedium
                        text: qsTr("Website")
                    }

                    onClicked: {
                        var props = {
                            "url": itemData.link
                        }
                        pageStack.push(Qt.resolvedUrl("WebPage.qml"), props);
                    }
                }
            }

            /*
            ListItem {
                width: parent.width

                Image {
                    id: shareIcon
                    x: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-l-share" +
                            (parent.highlighted ? "?highlighted" : "")
                }

                Label {
                    anchors.left: shareIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: qsTr("Share this")
                }

                onClicked: {
                    Qt.openUrlExternally("mailto:friend@email.com?title='Shared from Tidings'");
                }
            }
            */

            Item {
                visible: enclosureRepeater.count > 0
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

                delegate: MediaItem {
                    x: 2
                    width: column.width - 2
                    url: modelData.url
                    mimeType: modelData.type
                    length: modelData.length
                }
            }//Repeater

        }

        ScrollDecorator { }
    }

    BusyIndicator {
        running: urlLoader.loading || htmlFilter.busy
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }

    HintLoader {
        hint: articleHint
        when: configHintsEnabled.booleanValue &&
              page.status === PageStatus.Active
    }
}
