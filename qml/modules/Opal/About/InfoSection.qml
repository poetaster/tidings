//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import"../LinkHandler"as L
Column{id:root
spacing:0
width:parent.width
height:childrenRect.height
function openOrCopyUrl(externalUrl,title){L.LinkHandler.openOrCopyUrl(externalUrl,title)
}property alias title:_titleLabel.text
property string text:""
property string smallPrint:""
property string showMoreLabel:qsTranslate("Opal.About","show details")
property list<InfoButton>buttons
property alias enabled:_bgItem.enabled
default property alias contentItem:_contents.children
signal clicked
property alias _backgroundItem:_bgItem
property alias _titleItem:_titleLabel
property alias _textItem:_textLabel
property alias _smallPrintItem:_smallPrintLabel
property alias _showMoreLabelItem:_showMoreLabel
property list<DonationService>__donationButtons
BackgroundItem{id:_bgItem
enabled:false
width:parent.width
height:column.height
onClicked:root.clicked()
Column{id:column
width:parent.width-2*Theme.horizontalPageMargin
height:childrenRect.height
anchors.horizontalCenter:parent.horizontalCenter
spacing:0
Item{width:1
height:Theme.paddingSmall
}Label{id:_titleLabel
width:parent.width
horizontalAlignment:Text.AlignRight
wrapMode:Text.Wrap
font.pixelSize:Theme.fontSizeMedium
visible:text!==""
height:visible?implicitHeight+Theme.paddingSmall:0
color:Theme.highlightColor
}Item{id:_contents
width:parent.width
height:childrenRect.height
}Column{width:parent.width
spacing:Theme.paddingMedium
visible:root.text!==""||root.smallPrint!==""
Label{id:_textLabel
visible:root.text!==""
width:parent.width
horizontalAlignment:Text.AlignLeft
wrapMode:Text.Wrap
text:root.text
textFormat:Text.StyledText
linkColor:palette.secondaryColor
palette.primaryColor:Theme.highlightColor
onLinkActivated:openOrCopyUrl(link)
}Label{id:_smallPrintLabel
visible:smallPrint!==""
width:parent.width
horizontalAlignment:Text.AlignLeft
wrapMode:Text.Wrap
text:smallPrint
textFormat:Text.StyledText
linkColor:palette.secondaryColor
palette.primaryColor:Theme.highlightColor
font.pixelSize:Theme.fontSizeSmall
onLinkActivated:openOrCopyUrl(link)
}Row{id:showMoreRow
anchors.right:parent.right
spacing:Theme.paddingSmall
visible:root.enabled&&showMoreLabel!==""
height:visible?_showMoreLabel.height:0
Label{id:_showMoreLabel
font.pixelSize:Theme.fontSizeExtraSmall
textFormat:Text.StyledText
text:"<i>%1</i>".arg(showMoreLabel)
}Label{anchors.verticalCenter:_showMoreLabel.verticalCenter
text:" • • •"
}}}Item{width:1
height:root.text!==""?Theme.paddingMedium:0
}}}Item{width:1
height:(buttons.length>0||__donationButtons.length>0)?Theme.paddingMedium:0
}Column{width:parent.width
height:childrenRect.height
spacing:Theme.paddingMedium
Repeater{model:buttons
delegate:Button{anchors.horizontalCenter:parent.horizontalCenter
width:parent.width/4*3
height:visible?implicitHeight:0
visible:modelData.text!==""&&modelData.enabled===true
text:modelData.text
onClicked:modelData.clicked()
}}Repeater{model:__donationButtons
delegate:Button{anchors.horizontalCenter:parent.horizontalCenter
width:parent.width/4*3
height:visible?implicitHeight:0
visible:modelData.name!==""&&modelData.url!==""
text:modelData.name
onClicked:openOrCopyUrl(modelData.url)
}}}}