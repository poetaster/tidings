import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    property string _elapsedText

    function refreshElapsed() {
        _elapsedText = Format.formatDate(coverAdaptor.lastRefresh,
                                         Formatter.DurationElapsed);
    }

    Timer {
        triggeredOnStart: true
        running: cover.status === Cover.Active
        interval: 60000
        repeat: true

        onTriggered: {
            refreshElapsed();
        }
    }

    Image {
        id: backgroundImage
        visible: coverAdaptor.thumbnail !== "" &&
                 (coverAdaptor.currentPage === "ViewPage" ||
                  coverAdaptor.currentPage === "WebPage") &&
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
        width: parent.width
        height: width
        anchors.bottom: parent.bottom
        fillMode: Image.PreserveAspectCrop
        source: Qt.resolvedUrl("overlay.png")
        opacity: 0.1
    }

    // Main
    Column {
        visible: coverAdaptor.currentPage === "SourcesPage"

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
                anchors.right: parent.right
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "Tidings"
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
            visible: coverAdaptor.busy
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
            visible: ! coverAdaptor.busy
            width: parent.width
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: _elapsedText
        }
    }

    // Overview
    Column {
        visible: coverAdaptor.currentPage === "FeedsPage"

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
                text: coverAdaptor.totalCount
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
            visible: coverAdaptor.busy
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
            visible: ! coverAdaptor.busy
            width: parent.width
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: _elapsedText
        }
    }

    // News Item
    Column {
        visible: (coverAdaptor.currentPage === "ViewPage" ||
                  coverAdaptor.currentPage === "WebPage")

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
        enabled: ! coverAdaptor.busy &&
                 coverAdaptor.currentPage === "ViewPage" &&
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
        enabled: ! coverAdaptor.busy &&
                 coverAdaptor.currentPage === "ViewPage" &&
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
        enabled: ! coverAdaptor.busy &&
                 coverAdaptor.currentPage === "ViewPage" &&
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
        enabled: coverAdaptor.busy

        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: {
                coverAdaptor.abort();
            }
        }
    }

    // [refresh only]
    CoverActionList {
        enabled: ! coverAdaptor.busy &&
                 (coverAdaptor.currentPage === "SourcesPage" ||
                  coverAdaptor.currentPage === "FeedsPage" &&
                  coverAdaptor.totalCount === 0)

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
        enabled: ! coverAdaptor.busy &&
                 coverAdaptor.currentPage === "FeedsPage" &&
                 coverAdaptor.totalCount > 0

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


