import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root
    objectName: "WebPage"

    property string url

    // work around Silica bug: don't let webview enable forward navigation
    onForwardNavigationChanged: {
        if (forwardNavigation)
            forwardNavigation = false;
    }

    allowedOrientations: Orientation.All

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: parent.status === PageStatus.Active ? webComponent : undefined
    }

    Component {
        id: webComponent

        SilicaWebView {
            id: webview

            property int _backCount: 0
            property int _previousContentY;

            anchors.fill: parent

            PullDownMenu {
                // people have trouble getting back the page navigation
                // by zooming out (Silica is bit buggy, too), so offer a menu
                // option for going back
                MenuItem {
                    text: qsTr("Close web view")

                    onClicked: {
                        root.backNavigation = true;
                        pageStack.navigateBack(PageStackAction.Animated);
                    }
                }

                MenuItem {
                    text: qsTr("Open in browser")

                    onClicked: {
                        Qt.openUrlExternally(root.url);
                    }
                }
            }

            Component.onCompleted: {
                try
                {
                    experimental.userAgent =
                            "Mozilla/5.0 (Maemo; Linux; Jolla; Sailfish; Mobile) " +
                            "AppleWebKit/534.13 (KHTML, like Gecko) " +
                            "NokiaBrowser/8.5.0 Mobile Safari/534.13";
                    if (configFontScaleWebEnabled.booleanValue)
                    {
                        experimental.preferences.minimumFontSize =
                                Theme.fontSizeExtraSmall * (configFontScale.value / 100.0);
                    }

                }
                catch (err)
                {

                }
            }

            url: root.url

            onContentYChanged: {
                if (contentY < _previousContentY)
                {
                    ++_backCount;
                }
                else
                {
                    _backCount = 0;
                }

                if (_backCount >= 5)
                {
                    toolbar.anchors.bottomMargin = 0;
                }
                else
                {
                    toolbar.anchors.bottomMargin = -toolbar.height;
                }

                _previousContentY = contentY;
            }
        }

    }


    Item {
        id: toolbar
        width: parent.width
        height: Theme.itemSizeLarge

        anchors {
            bottom: parent.bottom
            Behavior on bottomMargin {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.darker(Theme.highlightColor)
        }

        IconButton {
            id: backBtn
            enabled: loader.item ? loader.item.canGoBack : false
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "image://theme/icon-m-back"

            onClicked: {
                loader.item.goBack();
            }
        }

        Label {
            id: titleLabel
            anchors.left: backBtn.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.right: stopReloadBtn.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: loader.item ? loader.item.title : ""
        }

        IconButton {
            id: stopReloadBtn
            enabled: loader.item
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            icon.source: !loader.item ? ""
                                      : loader.item.loading ? "image://theme/icon-m-reset"
                                                            : "image://theme/icon-m-refresh"

            onClicked: {
                if (loader.item.loading)
                {
                    loader.item.stop();
                }
                else
                {
                    loader.item.reload();
                }
            }
        }

    }

}
