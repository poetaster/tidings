import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidings 1.0

Dialog {
    id: page
    objectName: "ViewPageProxy"
    allowedOrientations: Orientation.All

    property var listview
    property int currentIndex: listview.currentIndex //-1
    property var _fakePreviousPage: null

    canAccept: listview.currentIndex < (listview.count - 1)
    acceptDestinationAction: PageStackAction.Replace
    acceptDestination: Qt.resolvedUrl('ViewPageProxy.qml')
    acceptDestinationProperties: { "listview": page.listview }
    onAccepted: {
        // This is called when the dialog is "accepted", i.e. when the user swiped
        // right or tapped the "next page" indicator. We then grab a tiny screenshot
        // and show this, while we hide the current page and update currentIndex.
        // This is necessary to avoid a bunch of segmentation faults that happened
        // when the current page updates itself while getting deactivated. It is
        // not possible to prevent ViewPage from updating itself when currentIndex
        // is changed. Showing the screenshot is necessary to avoid too much flickering
        // when the old page is being hidden.

        var fakeSuccess = viewLoader.item.grabToImage(function(result){
            _fakePreviousPage = result
            viewLoader.sourceComponent = fakePreviousPageComponent
            listview.currentIndex += 1
            console.debug("faking previous succeeded")
        }, Qt.size(Screen.width/20, Screen.height/20))

        if (!fakeSuccess) {
            console.log("faking previous page failed")
            //viewLoader.sourceComponent = undefined
            //listview.currentIndex += 1
            console.debug("proxypage: " + listview.currentIndex);
        }
    }

    Component {
        id: fakePreviousPageComponent
        Image {
            source: _fakePreviousPage !== null ? _fakePreviousPage.url : ''
            opacity: 0.7
        }
    }

    Loader {
        id: viewLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Component {
            ViewPage {
                listview: page.listview
                status: page.status
            }
        }
    }

    HintLoader {
        hint: articleHint
        when: configHintsEnabled.booleanValue &&
              page.status === PageStatus.Active
    }
}
