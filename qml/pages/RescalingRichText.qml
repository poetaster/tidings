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

    property bool active: true
    property string text
    property color color
    property real fontSize: Theme.fontSizeSmall
    property bool showSource: false

    property real scaling: 1

    property int _scaledFor: 0

    property string _style: "<style>" +
                            "a:link { color:" + Theme.highlightColor + "; }" +
                            "</style>"

    signal linkActivated(string link)

    height: contentLabel.sourceComponent !== null ? contentLabel.height * scaling
                                                  : 0
    clip: true

    onWidthChanged: {
        if (active)
        {
            layoutLabel.recalc();
        }
    }

    onTextChanged: {
        _scaledFor = 0;
        if (active)
        {
            layoutLabel.recalc();
        }
    }

    onActiveChanged: {
        if (active)
        {
            layoutLabel.recalc();
        }
    }

    Label {
        id: layoutLabel

        function recalc()
        {
            if (Math.ceil(parent.width) !== _scaledFor)
            {
                _scaledFor = Math.ceil(parent.width);
                text = "";
                width = parent.width;
                // tiny font so that only images are relevant
                text = "<style>* { font-size: 1px; }</style>" + parent.text;
            }
        }

        visible: false
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        textFormat: root.showSource ? Text.PlainText : Text.RichText

        Component.onCompleted: {
            if (active)
            {
                recalc();
            }
        }

        onPaintedWidthChanged: {
            if (paintedWidth > 0)
            {
                var contentWidth = Math.floor(paintedWidth);
                scaling = Math.min(1, parent.width / (paintedWidth + 0.0));
                console.log("scaling: " + scaling + " width: " + root.width);

                contentLabel.text = "";
                contentLabel.width = root.width / scaling;
                contentLabel.font.pixelSize = root.fontSize / scaling;
                contentLabel.scale = scaling;
                contentLabel.text = _style + root.text;
            }
        }
    }

    Label {
        id: contentLabel

        scale: scaling

        transformOrigin: Item.TopLeft
        color: root.color
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        textFormat: root.showSource ? Text.PlainText : Text.RichText
        smooth: true

        onLinkActivated: {
            root.linkActivated(link);
        }
    }
}
