//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import"../../LinkHandler"as L
import".."
import"."
SilicaListView{id:root
property list<ChangelogItem>changelogItems
property url changelogList
property int scrollbarType:ScrollbarType.auto
property Item _scrollbar:null
function _reloadScrollbar(){if(scrollbarType===ScrollbarType.plain){_scrollbar=null
return
}else if(scrollbarType===ScrollbarType.auto){var paragraphCount=0
var useAdvanced=false
for(var i in itemsLoader.effectiveItems){paragraphCount+=itemsLoader.effectiveItems[i].__effectiveEntries.length
if(paragraphCount>=20){useAdvanced=true
break
}}}if(useAdvanced===true||scrollbarType===ScrollbarType.advanced){try{_scrollbar=Qt.createQmlObject("\n                    import QtQuick 2.0\n                    import %1 1.0 as Private\n                    Private.Scrollbar {\n                        text: root.currentSection.split('|')[0]\n                        description: root.currentSection.split('|').slice(1).join('|')\n                        headerHeight: root.headerItem ? root.headerItem.height : 0\n                    }".arg("Sailfish.Silica.private"),root,"Scrollbar")
}catch(e){if(!_scrollbar){console.warn(e)
console.warn("[Opal.About] bug: failed to load customized scrollbar")
console.warn("[Opal.About] bug: this probably means the private API has changed")
}}}}model:itemsLoader.effectiveItems
spacing:Theme.paddingMedium
quickScroll:!_scrollbar
section.property:"__effectiveSection"
onScrollbarTypeChanged:_reloadScrollbar()
footer:Item{width:parent.width
height:Theme.horizontalPageMargin
}delegate:Column{id:item
width:root.width
height:childrenRect.height
spacing:Theme.paddingSmall
property int textFormat:model.textFormat
property var paragraphs:model.__effectiveEntries
Item{width:1
height:Theme.paddingMedium
}Label{width:parent.width-2*x
x:Theme.horizontalPageMargin
horizontalAlignment:Text.AlignRight
font.pixelSize:Theme.fontSizeSmall
truncationMode:TruncationMode.Fade
color:palette.highlightColor
text:model.version
}Label{width:parent.width-2*x
x:Theme.horizontalPageMargin
horizontalAlignment:Text.AlignRight
font.pixelSize:Theme.fontSizeSmall
font.italic:true
truncationMode:TruncationMode.Fade
color:palette.secondaryHighlightColor
visible:haveAuthor||haveDate
property bool haveAuthor:!!model.author
property bool haveDate:!isNaN(model.date.valueOf())
text:{if(haveAuthor&&haveDate){Qt.formatDate(model.date,Qt.DefaultLocaleShortDate)+", "+model.author
}else if(haveAuthor){model.author
}else if(haveDate){Qt.formatDate(model.date,Qt.DefaultLocaleShortDate)
}else{""
}}}Repeater{model:item.paragraphs
Label{width:parent.width-2*x
x:Theme.horizontalPageMargin
font.pixelSize:Theme.fontSizeSmall
color:Theme.highlightColor
wrapMode:Text.Wrap
textFormat:item.textFormat
text:modelData
linkColor:Theme.primaryColor
onLinkActivated:L.LinkHandler.openOrCopyUrl(link)
bottomPadding:Theme.paddingMedium
}}}ChangelogItemsLoader{id:itemsLoader
changelogItems:root.changelogItems
changelogList:root.changelogList
onEffectiveItemsChanged:_reloadScrollbar()
}VerticalScrollDecorator{flickable:root
visible:!root._scrollbar||scrollbarType===ScrollbarType.none
}}