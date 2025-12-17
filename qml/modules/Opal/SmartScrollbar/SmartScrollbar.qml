//@ This file is part of opal-smartscrollbar.
//@ https://github.com/Pretty-SFOS/opal-smartscrollbar
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
QtObject{id:root
property Flickable flickable:null
property string text
property string description
property bool smartWhen:true
property bool quickScrollWhen:true
readonly property bool usingFallback:_fallback.visible
function reload(){try{_scrollbar=Qt.createQmlObject("\n                import QtQuick 2.0\n                import %1 1.0 as Private\n                Private.Scrollbar {\n                    visible: root.smartWhen\n                    enabled: visible\n                    text: root.text\n                    description: root.description\n                    headerHeight: root._headerHeight\n                }".arg("Sailfish.Silica.private"),flickable,"SmartScrollbar")
}catch(e){if(!_scrollbar){console.warn(e)
console.warn("[BUG] failed to load smart scrollbar")
console.warn("[BUG] this probably means the private API has changed")
}}}property int _headerHeight:!!flickable&&flickable.headerItem?flickable.headerItem.height:0
property VerticalScrollDecorator _fallback:VerticalScrollDecorator{parent:root.flickable
flickable:root.flickable
visible:(!root._scrollbar||!root.smartWhen)&&!!flickable&&flickable.contentHeight>Screen.height
}
property Item _scrollbar:null
property Binding __quickScroll:Binding{target:flickable
property:"quickScroll"
value:false
when:!quickScrollWhen
}
Component.onCompleted:{reload()
}}