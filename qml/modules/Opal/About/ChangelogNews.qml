//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import"private/functions.js"as Func
import"private"
Item{id:root
property list<ChangelogItem>changelogItems
property url changelogList
property string _applicationName:Qt.application.name
property string _organizationName:Qt.application.organization
readonly property string __lastVersion:!!configLoader.item?configLoader.item.lastVersion:""
readonly property string __configPath:"/settings/opal/opal-about/"+"changelog-overlay/%1/%2".arg(_organizationName).arg(_applicationName)
property list<ChangelogItem>__filteredItems
property int __ready:(configLoader.status===Loader.Ready?1:0)+(itemsLoader.effectiveItems.length>0?1:0)
function show(){showTimer.stop()
pageStack.completeAnimation()
pageStack.push(dialogComponent)
}function _markAsRead(){if(__filteredItems.length===0){return
}var latestChangelogVersion=__filteredItems[0].version
configLoader.item.lastVersion=latestChangelogVersion
}Component.onCompleted:{if(!_applicationName||!_organizationName){console.warn("[Opal.About] both application name and organisation name "+"must be set in order to use the changelog overlay")
console.warn("[Opal.About] note that these properties are also required "+"for Sailjail sandboxing")
console.warn("[Opal.About] see: https://github.com/sailfishos/"+"sailjail-permissions#desktop-file-changes")
}}on__ReadyChanged:{if(__ready<2||itemsLoader.effectiveItems.length===0||__filteredItems.length>0)return
if(!!__lastVersion){var loadedItems=[]
for(var i in itemsLoader.effectiveItems){if(itemsLoader.effectiveItems[i]===null){continue
}var v=itemsLoader.effectiveItems[i].version
if(v===__lastVersion){break
}console.log("[Opal.About] showing changelog for:",v)
loadedItems.push(itemsLoader.effectiveItems[i])
}if(loadedItems.length>0){__filteredItems=loadedItems
showTimer.start()
}else{__filteredItems=itemsLoader.effectiveItems
}}else{__filteredItems=itemsLoader.effectiveItems
_markAsRead()
__ready=-1
}}Loader{id:configLoader
sourceComponent:!!_applicationName&&!!_organizationName?configComponent:null
asynchronous:true
}ChangelogItemsLoader{id:itemsLoader
changelogItems:root.changelogItems
changelogList:root.changelogList
}Timer{id:showTimer
interval:10
repeat:true
running:false
onTriggered:{if(pageStack.busy||pageStack.depth===0)return
show()
}}Component{id:configComponent
ConfigurationGroup{path:root.__configPath
property string lastVersion:""
}}Component{id:dialogComponent
Dialog{allowedOrientations:Orientation.All
onDone:_markAsRead()
ChangelogView{anchors.fill:parent
changelogItems:root.__filteredItems
header:PageHeader{title:qsTranslate("Opal.About","News")
description:qsTranslate("Opal.About","Changes since version %1").arg(__lastVersion)
descriptionWrapMode:Text.Wrap
}}}}}