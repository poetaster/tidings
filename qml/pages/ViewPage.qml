import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "ViewPage"

    property int index: 0
    property string feedName: newsBlendModel.get(index).name
    property string title: newsBlendModel.get(index).title
    property string preview: newsBlendModel.get(index).description
    property string encoded: newsBlendModel.get(index).encoded
    property string url: newsBlendModel.get(index).link
    property string color: newsBlendModel.get(index).color
    property string date: newsBlendModel.get(index).date
    property bool read: newsBlendModel.get(index).read
    property variant enclosures: newsBlendModel.get(index).enclosures
    property string duration: newsBlendModel.get(index).duration
    property bool shelved: newsBlendModel.isShelved(index)

    property int _previousOfFeed: newsBlendModel.previousOfFeed(index)
    property int _nextOfFeed: newsBlendModel.nextOfFeed(index)

    function previousItem() {
        var props = {
            "index": index - 1
        };
        pageStack.replace("ViewPage.qml", props);
    }

    function nextItem() {
        var props = {
            "index": index + 1
        };
        pageStack.replace("ViewPage.qml", props);
    }

    function goToItem(idx) {
        var props = {
            "index": idx
        };
        pageStack.replace("ViewPage.qml", props);
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
        navigationState.openedItem(index);
        if (! read) {
            newsBlendModel.setRead(index, true);
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && url !== "")
        {
            var props = {
                "url": url
            }
            pageStack.pushAttached(Qt.resolvedUrl("WebPage.qml"), props);
        }
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
        width: 2
        height: parent.height
        color: page.color
    }

    SilicaFlickable {
        id: contentFlickable

        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: shelved ? "Don't keep it"
                              : "Keep it"

                onClicked: {
                    newsBlendModel.shelveItem(index, ! shelved);
                    shelved = ! shelved;
                }
            }

            MenuItem {
                enabled: _previousOfFeed !== -1
                text: "<" + feedName + ">"

                onClicked: {
                    goToItem(_previousOfFeed);
                }
            }
            MenuItem {
                enabled: index > 0
                text: enabled ? qsTr("Previous")
                              : qsTr("Already at the beginning")

                onClicked: {
                    goToItem(index - 1)
                }
            }
        }

        PushUpMenu {
            MenuItem {
                enabled: index < newsBlendModel.count - 1
                text: enabled ? qsTr("Next")
                              : qsTr("Already at the end")

                onClicked: {
                    goToItem(index + 1)
                }
            }
            MenuItem {
                enabled: _nextOfFeed !== -1
                text: "<" + feedName + ">"

                onClicked: {
                    goToItem(_nextOfFeed);
                }
            }
        }

        Column {
            id: column
            width: parent.width
            height: childrenRect.height

            PageHeader {
                id: pageHeader
                title: page.feedName
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
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: page.title

                    MouseArea {
                        enabled: page.url !== ""
                        anchors.fill: parent
                        onClicked: {
                            var props = {
                                "url": page.url
                            }
                            pageStack.push(Qt.resolvedUrl("ExternalLinkDialog.qml"),
                                           props);
                        }
                    }
                }

                Image {
                    id: shelveIcon
                    anchors.right: parent.right
                    source: shelved ? "image://theme/icon-l-favorite"
                                    : "image://theme/icon-l-star"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            newsBlendModel.shelveItem(index, ! shelved);
                            shelved = ! shelved;
                        }
                    }
                }
            }

            Label {
                visible: duration !== undefined && duration > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignLeft
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("(%1 seconds)").arg(duration)
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignLeft
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: Format.formatDate(page.date, Formatter.Timepoint)
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

                color: Theme.primaryColor
                fontSize: Theme.fontSizeSmall
                text: page.encoded ? page.encoded : page.preview

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
                model: enclosures

                ListItem {
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
                        source: enclosureRepeater.count ? _mediaIcon(model.url, model.type) : ""
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
                        text: _urlFilename(model.url)
                    }
                    Label {
                        anchors.top: mediaNameLabel.bottom
                        anchors.left: mediaNameLabel.left
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: _mediaTypeName(model.type)
                    }
                    Label {
                        anchors.top: mediaNameLabel.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: model.length >= 0 ? Format.formatFileSize(model.length)
                                                : ""
                    }

                    onClicked: {
                        Qt.openUrlExternally(model.url);
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
