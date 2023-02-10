import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Page {
    id: root
    objectName: "WebPage"

    property string url

    allowedOrientations: Orientation.All

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: parent.status === PageStatus.Active ? webComponent : undefined
    }

    Component {
        id: webComponent

        WebView {
            anchors.fill: parent

            id: webview
            httpUserAgent: "Mozilla/5.0 (Mobile; rv:78.0) Gecko/78.0 Firefox/78.0"

            /* This will probably be required from 4.4 on. */
            Component.onCompleted: {
                WebEngineSettings.setPreference("security.disable_cors_checks", true, WebEngineSettings.BoolPref)
                WebEngineSettings.setPreference("security.fileuri.strict_origin_policy", false, WebEngineSettings.BoolPref)
                    if (configFontScaleWebEnabled.booleanValue)
                    {
                        experimental.preferences.minimumFontSize =
                                Theme.fontSizeExtraSmall * (configFontScale.value / 100.0);
                    }

            }
            onRecvAsyncMessage: {

                console.debug(message)
                switch (message) {
                case "embed:contentOrientationChanged":
                    break
                case "webview:action":
                    if ( data.key != val ) {
                        //if (debug) console.debug(data.src)
                    }
                    break
                }

            }

            //property int _backCount: 0
            //property int _previousContentY;

            url: root.url

            onLoadingChanged: {}
        }

    }
/*
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
*/
}
