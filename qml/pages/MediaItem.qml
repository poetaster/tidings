import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0

ListItem {
    id: item

    property string url
    property string mimeType
    property int length

    property bool _isAudio: mimeType.substring(0, 6) === "audio/"

    function _toTime(s)
    {
        if (s < 0)
        {
            return "-";
        }

        s /= 1000;
        var seconds = Math.floor(s) % 60;
        s /= 60;
        var minutes = Math.floor(s) % 60;
        s /= 60;
        var hours = Math.floor(s);

        if (seconds < 10)
        {
            seconds = "0" + seconds;
        }
        if (minutes < 10)
        {
            minutes = "0" + minutes;
        }

        if (hours > 0)
        {
            return hours + ":" + minutes + ":" + seconds;
        }
        else
        {
            return minutes + ":" + seconds;
        }
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
        if (type.substring(0, 6) === "image/") {
            return url;
        } else {
            return "image://theme/icon-m-other";
        }
    }

    /* Returns a user-friendly media type name for the given MIME type.
     */
    function _mediaTypeName(type) {
        if (type.substring(0, 6) === "image/") {
            return qsTr("Image");
        } else if (type.substring(0, 6) === "video/") {
            return qsTr("Video");
        } else if (type === "application/pdf") {
            return qsTr("PDF document");
        } else {
            return type;
        }
    }

    Audio {
        id: audio
        source: _isAudio ? item.url
                         : ""
        autoLoad: false
        autoPlay: false

        onPositionChanged: {
            if (! slider.down)
            {
                slider.value = position;
            }
        }

        onDurationChanged: {
            slider.maximumValue = duration;
        }
    }

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
        source: ! _isAudio ? _mediaIcon(item.url, item.mimeType)
                           : audio.playbackState === Audio.PlayingState ? "image://theme/icon-l-pause"
                                                                        : "image://theme/icon-l-play"
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
        text: _urlFilename(item.url)
    }
    Label {
        id: label1
        anchors.top: mediaNameLabel.bottom
        anchors.left: mediaNameLabel.left
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: slider.visible ? _toTime(slider.value) : _mediaTypeName(item.mimeType)
    }
    Label {
        id: label2
        anchors.top: mediaNameLabel.bottom
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: slider.visible ? _toTime(audio.duration)
                             : item.length >= 0 ? Format.formatFileSize(item.length)
                                                : ""
    }

    Slider {
        id: slider

        visible: _isAudio
        enabled: audio.playbackState === Audio.PlayingState ||
                 audio.playbackState === Audio.PausedState

        anchors.left: label1.right
        anchors.right: label2.left
        anchors.verticalCenter: label1.verticalCenter

        leftMargin: Theme.paddingSmall
        rightMargin: Theme.paddingSmall
        height: Theme.itemSizeSmall / 3

        handleVisible: false
        minimumValue: 0

        onDownChanged: {
            if (! down)
            {
                audio.seek(value);
                if (audio.playbackState !== Audio.PlayingState)
                {
                    audio.play();
                }
            }
        }
    }

    onClicked: {
        if (_isAudio)
        {
            if (audio.playbackState == Audio.PlayingState)
            {
                audio.pause();
            }
            else
            {
                audio.play();
            }
        }
        else
        {
            Qt.openUrlExternally(item.url);
        }
    }

}
