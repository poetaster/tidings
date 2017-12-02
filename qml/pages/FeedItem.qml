import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: feedItem

    property alias name: nameLabel.text
    property date timestamp
    property string logo
    property var thumbnails: []
    property alias colorTag: colorTagBar.color
    property int totalCount: 0
    property int unreadCount: 0
    property alias busy: busyIndicator.running

    property int _thumbnailOffset: 0

    function cycleThumbnails()
    {
        if (thumbnails.length > 0)
        {
            cycleThumbnailsAnimation.start();
        }
    }

    clip: true

    onThumbnailsChanged: {
        _thumbnailOffset = 0;
    }

    SequentialAnimation {
        id: cycleThumbnailsAnimation

        NumberAnimation {
            target: thumbImage
            property: "x"
            from: 0
            to: -thumbImage.width
            easing.type: Easing.InOutQuad
            duration: 300
        }

        ScriptAction {
            script: {
                _thumbnailOffset = (_thumbnailOffset + 1) % thumbnails.length;
                thumbImage.x = 0;
            }
        }
    }

    Rectangle {
        id: feedThumbnail
        visible: thumbnails.length > 0 && configShowPreviewImages.booleanValue
        anchors.fill: parent
        color: "black"
        opacity: 0.4

        Image {
            id: thumbImage
            x: 0
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: thumbnails.length > 0 ? thumbnails[_thumbnailOffset] : ""
        }

        Image {
            id: thumbImage2
            anchors.left: thumbImage.right
            width: thumbImage.width
            height: thumbImage.height
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: thumbnails.length > 0 ? thumbnails[(_thumbnailOffset + 1) % thumbnails.length] : ""
        }
    }

    Image {
        id: feedBackground
        visible: ! feedThumbnail.visible
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: height
        fillMode: Image.PreserveAspectFit
        source: Qt.resolvedUrl("../cover/overlay.png")
        opacity: 0.1
    }

    // color tag tint
    Rectangle {
        visible: configTintedItems.booleanValue
        anchors.fill: parent
        color: colorTag
        opacity: 0.1
    }

    // color tag bar
    Rectangle {
        id: colorTagBar
        width: 2
        height: parent.height
    }

    // logo of feed, if the feed has one
    Image {
        visible: logo !== ""
        width: parent.width
        height: parent.height / 4
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: colorTagBar.width
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignBottom
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        source: logo
    }

    Label {
        id: unreadCountLabel
        visible: ! busy
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeHuge
        color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        text: unreadCount > 0 ? unreadCount : "✓"
    }

    Label {
        id: totalCountLabel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        text: totalCount
    }

    Label {
        id: nameLabel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: totalCountLabel.left
        anchors.leftMargin: Theme.paddingSmall + 2
        anchors.rightMargin: 2 * Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        truncationMode: TruncationMode.Fade
    }

    /*
    Label {
        id: timeLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: nameLabel.bottom
        anchors.leftMargin: Theme.paddingSmall
        anchors.rightMargin: Theme.paddingSmall
        horizontalAlignment: Qt.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall * 0.8
        color: feedItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        elide: Text.ElideRight
        text: (minuteTimer.tick && timestamp && timestamp.getMilliseconds() > 0)
              ? Format.formatDate(timestamp, Formatter.DurationElapsed)
              : ""
    }
    */

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Medium
    }
}
