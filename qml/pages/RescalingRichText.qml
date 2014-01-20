import QtQuick 2.0
import Sailfish.Silica 1.0

/* Pretty fancy element for displaying rich text fitting the width.
 *
 * Images are scaled down to fit the width, or, technically speaking, the
 * rich text content is actually scaled down so the images fit, while the
 * font size is scaled up to keep the original font size.
 */
Item {
    id: root

    property string text
    property alias color: contentLabel.color
    property real fontSize: Theme.fontSizeSmall

    property real scaling: 1
    property bool isScaled

    property string _style: "<style>" +
                            "a:link { color:" + Theme.highlightColor + "}" +
                            "</style>"

    signal linkActivated(string link)

    height: contentLabel.height * scaling
    clip: true

    onWidthChanged: {
        isScaled = false;
        rescaleTimer.restart();
    }

    Label {
        id: contentLabel

        width: parent.width / scaling
        scale: scaling

        transformOrigin: Item.TopLeft
        font.pixelSize: parent.fontSize / scaling
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        textFormat: Text.RichText
        smooth: true

        text: _style + parent.text

        onContentWidthChanged: {
            console.log("contentWidth: " + contentWidth);
            rescaleTimer.restart();
        }

        onLinkActivated: {
            root.linkActivated(link);
        }
    }

    Timer {
        id: rescaleTimer
        interval: 100

        onTriggered: {
            var contentWidth = Math.floor(contentLabel.contentWidth);
            if (! isScaled)
            {
                isScaled = true;
                scaling = parent.width / (contentLabel.contentWidth + 0.0);
                console.log("scaling: " + scaling);
            }
        }
    }
}
