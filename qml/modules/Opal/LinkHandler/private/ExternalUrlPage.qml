//@ This file is part of opal-linkhandler.
//@ https://github.com/Pretty-SFOS/opal-linkhandler
//@ SPDX-FileCopyrightText: 2021-2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import Sailfish.Share 1.0
Page{id:root
property url externalUrl
property string title:""
allowedOrientations:Orientation.All
ShareAction{id:shareHandler
mimeType:"text/x-url"
title:qsTranslate("Opal.LinkHandler","Share link")
}Notification{id:copyNotification
previewSummary:qsTranslate("Opal.LinkHandler","Copied to clipboard: %1").arg(Clipboard.text)
isTransient:true
appIcon:"icon-lock-information"
icon:"icon-lock-information"
}Column{width:parent.width
spacing:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeSmall
y:(root.orientation&Orientation.LandscapeMask&&Screen.sizeCategory<=Screen.Medium)?Theme.paddingLarge:Theme.itemSizeExtraLarge
Label{text:title?title:qsTranslate("Opal.LinkHandler","External Link")
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeExtraLarge
wrapMode:Text.Wrap
}Label{text:externalUrl
width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
horizontalAlignment:Text.AlignHCenter
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeMedium
wrapMode:Text.Wrap
}}Column{anchors{bottom:parent.bottom
bottomMargin:(root.isLandscape&&Screen.sizeCategory<=Screen.Medium)?Theme.itemSizeExtraSmall:Theme.itemSizeMedium
}width:parent.width
spacing:Theme.paddingLarge
ButtonLayout{id:firstRow
preferredWidth:(root.isPortrait||Screen.sizeCategory>Screen.Medium)?Theme.buttonWidthLarge:Theme.buttonWidthSmall
Button{text:qsTranslate("Opal.LinkHandler","Copy text to clipboard")
visible:title
onClicked:{Clipboard.text=title
copyNotification.publish()
pageStack.pop()
}}Button{ButtonLayout.newLine:root.isPortrait||Screen.sizeCategory>Screen.Medium
text:qsTranslate("Opal.LinkHandler","Copy to clipboard")
onClicked:{Clipboard.text=externalUrl
copyNotification.publish()
pageStack.pop()
}}}ButtonLayout{preferredWidth:firstRow.preferredWidth
Button{text:qsTranslate("Opal.LinkHandler","Share")
onClicked:{shareHandler.resources=[{"type":"text/x-url","linkTitle":title,"status":externalUrl.toString()}]
shareHandler.trigger()
pageStack.pop()
}}Button{ButtonLayout.newLine:root.isPortrait||Screen.sizeCategory>Screen.Medium
text:/^http[s]?:\/\// .test(externalUrl)?qsTranslate("Opal.LinkHandler","Open in browser"):qsTranslate("Opal.LinkHandler","Open externally")
onClicked:{Qt.openUrlExternally(externalUrl)
pageStack.pop()
}}}}}