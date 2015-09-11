import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: loader

    property Hint hint
    property bool when

    visible: false
    width: parent.width
    height: parent.height

    Component.onCompleted: {
        if (when && (! hint._shown || hint.repeat))
        {
            inAnimation.start();
        }
    }

    onWhenChanged: {
        if (when && (! hint._shown || hint.repeat))
        {
            inAnimation.start();
        }
    }

    SequentialAnimation {
        id: inAnimation

        ScriptAction {
            script: {
                loader.visible = true;
            }
        }

        NumberAnimation {
            target: curtain
            property: "opacity"
            to: 0.9
            duration: 300
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: column
            property: "y"
            to: loader.height - column.height
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    SequentialAnimation {
        id: outAnimation

        NumberAnimation {
            target: column
            property: "y"
            to: loader.height
            duration: 300
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: curtain
            property: "opacity"
            to: 0.0
            duration: 300
            easing.type: Easing.InOutQuad
        }

        ScriptAction {
            script: {
                loader.visible = false;
                hint._shown = true;
            }
        }
    }

    Rectangle {
        id: curtain
        anchors.fill: parent
        opacity: 0

        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: (loader.height - column.height) / loader.height; color: "black" }
            GradientStop { position: 1; color: "black" }
        }
    }

    Column {
        id: column
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingMedium
        y: loader.height
        height: childrenRect.height

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeHuge
            text: hint.title
        }

        Item {
            width: 1
            height: Theme.paddingSmall
        }

        Repeater {
            model: hint.items

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                text: modelData
            }
        }

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            horizontalAlignment: Text.AlignHCenter
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            font.italic: true
            text: qsTr("No more hints? Disable them in Settings.")
        }

        Item {
            width: 1
            height: Theme.paddingSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            outAnimation.start();
        }
    }
}
