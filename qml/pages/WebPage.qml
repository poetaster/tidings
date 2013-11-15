import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property alias url: webview.url

    // work around Silica bug: don't let webview enable forward navigation
    onForwardNavigationChanged: {
        if (forwardNavigation)
            forwardNavigation = false;
    }

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    SilicaWebView {
        id: webview

        header: PageHeader {
            title: webview.title
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Open in browser")

                onClicked: {
                    Qt.openUrlExternally(url);
                }
            }
        }

        anchors.fill: parent
    }

}
