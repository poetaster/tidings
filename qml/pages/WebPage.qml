import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    property string url

    // work around Silica bug: don't let webview enable forward navigation
    onForwardNavigationChanged: {
        if (forwardNavigation)
            forwardNavigation = false;
    }

    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    Loader {
        anchors.fill: parent
        sourceComponent: parent.status === PageStatus.Active ? webComponent : undefined
    }

    Component {
        id: webComponent

        SilicaWebView {
            id: webview

            header: PageHeader {
                title: webview.title
            }

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

            url: root.url
        }
    }


}
