import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    function refreshElapsed() {
        labelElapsed.text = Format.formatDate(newsBlendModel.lastRefresh,
                                              Formatter.DurationElapsed);
    }

    onStatusChanged: {
        if (status === Cover.Active) {
            refreshElapsed();
        }
    }

    Image {
        id: backgroundImage
        visible: coverAdaptor.thumbnail !== "" &&
                 coverAdaptor.mode === "feeds" &&
                 status === Image.Ready
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        source: coverAdaptor.thumbnail

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#80000000" }
                GradientStop { position: 0.6; color: "#80000000" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    OpacityRampEffect {
        sourceItem: backgroundImage
        direction: 3
        slope: 2.0
        offset: 0.5
    }

    Image {
        visible: ! backgroundImage.visible
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        source: Qt.resolvedUrl("overlay.png")
        opacity: 0.1
    }

    Column {
        visible: coverAdaptor.mode === "overview"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        width: parent.width

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Item {
            width: parent.width
            height: childrenRect.height

            Label {
                anchors.left: parent.left
                anchors.right: amountLabel.left
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "Tidings"
            }

            Label {
                id: amountLabel
                anchors.right: parent.right
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: newsBlendModel.count
            }
        }

        Separator {
            width: parent.width
            color: Theme.secondaryColor
        }

        Item {
            width: 1
            height: 2 * Theme.paddingLarge
        }

        Label {
            visible: newsBlendModel.busy
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: qsTr("Refreshing")

            Timer {
                property int angle: 0

                running: cover.status === Cover.Active && parent.visible
                interval: 50
                repeat: true

                onTriggered: {
                    var a = angle;
                    parent.opacity = 0.5 + 0.5 * Math.sin(angle * (Math.PI / 180.0));
                    angle = (angle + 10) % 360;
                }
            }
        }

        Label {
            id: labelElapsed
            visible: ! newsBlendModel.busy
            width: parent.width
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }

    Column {
        visible: coverAdaptor.mode === "feeds"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        width: parent.width

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Item {
            width: parent.width
            height: childrenRect.height

            Label {
                anchors.left: parent.left
                anchors.right: pageLabel.left
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: coverAdaptor.feedName
            }

            Label {
                id: pageLabel
                anchors.right: parent.right
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: coverAdaptor.page
            }
        }

        Separator {
            width: parent.width
            color: Theme.secondaryColor
        }

        Item {
            width: 1
            height: Theme.paddingSmall
        }

        Label {
            width: parent.width
            color: Theme.primaryColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeSmall
            maximumLineCount: 6
            text: coverAdaptor.title
        }
    }



    // [previous] and [next]
    CoverActionList {
        enabled: ! newsBlendModel.busy &&
                 coverAdaptor.mode === "feeds" &&
                 coverAdaptor.hasPrevious &&
                 coverAdaptor.hasNext

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                coverAdaptor.previousItem();
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                coverAdaptor.nextItem();
            }
        }
    }

    // [previous] only
    CoverActionList {
        enabled: ! newsBlendModel.busy &&
                 coverAdaptor.mode === "feeds" &&
                 coverAdaptor.hasPrevious &&
                 ! coverAdaptor.hasNext

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                coverAdaptor.previousItem();
            }
        }
    }

    // [next] only
    CoverActionList {
        enabled: ! newsBlendModel.busy &&
                 coverAdaptor.mode === "feeds" &&
                 ! coverAdaptor.hasPrevious &&
                 coverAdaptor.hasNext

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                coverAdaptor.nextItem();
            }
        }
    }

    // [abort] while loading
    CoverActionList {
        enabled: newsBlendModel.busy

        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: {
                coverAdaptor.abort();
            }
        }
    }

    // [refresh only]
    CoverActionList {
        enabled: ! newsBlendModel.busy &&
                 newsBlendModel.count === 0 &&
                 coverAdaptor.mode === "overview"

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: {
                coverAdaptor.refresh();
                refreshElapsed();
            }
        }
    }

    // [next] and [refresh]
    CoverActionList {
        enabled: ! newsBlendModel.busy &&
                 newsBlendModel.count > 0 &&
                 coverAdaptor.mode === "overview"

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                coverAdaptor.firstItem();
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: {
                coverAdaptor.refresh();
                refreshElapsed();
            }
        }
    }
}


