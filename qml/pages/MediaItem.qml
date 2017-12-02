import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: item

    property string url
    property string mimeType
    property int length

    property bool _isAudio: mimeType.substring(0, 6) === "audio/"
    property bool _isImage: mimeType.substring(0, 6) === "image/"

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
        } else if (type.substring(0, 6) === "video/") {
            return "image://theme/icon-l-play";
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

    onClicked: {
        if (_isAudio)
        {
            if (audioProxy.playing)
            {
                audioProxy.pause();
            }
            else
            {
                audioProxy.play();
            }
        }
        else if (_isImage)
        {
            var props = {
                "url": item.url,
                "name": _urlFilename(item.url)
            }
            pageStack.push(Qt.resolvedUrl("ImagePage.qml"), props);
        }
        else
        {
            Qt.openUrlExternally(item.url);
        }
    }

    QtObject {
        id: audioProxy

        property bool _active: audioPlayer.source == source
        property bool playing: _active ? audioPlayer.playing
                                       : false
        property bool paused: _active ? audioPlayer.paused
                                      : false
        property real duration: _active ? audioPlayer.duration
                                        : -1
        property real position: _active ? audioPlayer.position
                                        : 0

        property string source: _isAudio ? item.url : ""

        property Timer _seeker: Timer {
            interval: 50

            onTriggered: {
                if (audioProxy._active)
                {
                    if (! audioPlayer.playing)
                    {
                        console.log("Stream is not ready. Deferring seek operation.")
                        _seeker.start();
                    }
                    else
                    {
                        audioPlayer.seek(Math.max(0, database.audioBookmark(audioProxy.source) - 3000));
                    }
                }
            }
        }

        function play()
        {
            if (_active)
            {
                audioPlayer.play();
            }
            else
            {
                // save bookmark before switching to another podcast
                if (audioPlayer.playing)
                {
                    database.setAudioBookmark(audioPlayer.source,
                                               audioPlayer.position);
                }

                audioPlayer.stop();
                audioPlayer.source = source;
                audioPlayer.play();
                _seeker.start();
            }
        }

        function pause()
        {
            if (_active)
            {
                database.setAudioBookmark(source, audioPlayer.position);
                audioPlayer.pause();
            }
        }

        function seek(value)
        {
            if (_active) audioPlayer.seek(value);
        }

        onPositionChanged: {
            if (_active)
            {
                if (! slider.down)
                {
                    slider.value = position;
                }
            }
        }

        onDurationChanged: {
            if (_active)
            {
                slider.maximumValue = duration;
            }
        }
    }

    Image {
        id: mediaIcon

        anchors.left: parent.left
        //anchors.leftMargin: Theme.paddingLarge
        width: height
        height: parent.height
        asynchronous: true
        smooth: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        source: ! _isAudio ? _mediaIcon(item.url, item.mimeType)
                           : audioProxy.playing ? "image://theme/icon-l-pause"
                                                : "image://theme/icon-l-play"
        clip: true

        BusyIndicator {
            running: parent.status === Image.Loading
            anchors.centerIn: parent
            size: BusyIndicatorSize.Medium
        }
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
        text: ! slider.visible ? _mediaTypeName(item.mimeType)
                               : audioProxy.playing ? _toTime(slider.sliderValue)
                                                    : _toTime(database.audioBookmark(audioProxy.source))
    }
    Label {
        id: label2
        anchors.top: mediaNameLabel.bottom
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: slider.visible ? _toTime(audioProxy.duration)
                             : item.length >= 0 ? Format.formatFileSize(item.length)
                                                : ""
    }

    Slider {
        id: slider

        visible: _isAudio
        enabled: audioProxy.playing || audioProxy.paused

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
                audioProxy.seek(sliderValue);
                if (! audioProxy.playing)
                {
                    audioProxy.play();
                }
            }
        }

    }//Slider

}
