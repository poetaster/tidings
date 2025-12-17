//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Qt.labs.folderlistmodel 2.1
FolderListModel{id:root
property var loadedAttributions:([])
property bool enabled:false
property int _expectedCount:0
property int _objectsCreated:0
property int _round:0
folder:enabled?Qt.resolvedUrl("../../Attributions"):""
rootFolder:folder
showDirs:false
showFiles:true
showHidden:false
showOnlyReadable:true
sortField:FolderListModel.Unsorted
nameFilters:["Opal*Attribution.qml"]
onCountChanged:{console.log("[Opal.About] loading",root.count,"Opal attributions | round",_round)
var count=root.count
loadedAttributions=[]
_expectedCount=count
_objectsCreated=0
_round+=1
var round=_round
var i=0
while(i<count){var url=root.get(i,"fileURL")
var name=root.get(i,"fileBaseName")
createObjectAsync(url,name,{},root,function(object,url,name){if(round!=_round){console.log("[Opal.About] discarding outdated attribution:",name)
return
}console.log("[Opal.About] loaded attribution:",name)
_objectsCreated+=1
if(!!object){loadedAttributions.push(object)
}if(_objectsCreated>=_expectedCount){loadedAttributions.sort(function(a,b){return a.name.localeCompare(b.name)
})
loadedAttributions=loadedAttributions
}})
i+=1
}}function createObjectAsync(url,name,properties,parent,callback){var comp=Qt.createComponent(Qt.resolvedUrl(url),Component.Asynchronous,root)
function _finishComponent(){if(comp.status===Component.Error){console.log("[Opal] Failed to create component “%1”:".arg(name),comp.errorString)
callback(null,url,name)
return true
}else if(comp.status===Component.Ready){var incubator=comp.incubateObject(parent,properties,Qt.Asynchronous)
function _finishObject(){if(incubator.status===Component.Error){console.log("[Opal] Failed to create object “%1”".arg(name))
console.log(incubator.errorString)
callback(null,url,name)
return true
}else if(incubator.status===Component.Ready){callback(incubator.object,url,name)
return true
}return false
}
if(!_finishObject()){incubator.onStatusChanged=function(status){_finishObject()
}
}return true
}return false
}
if(!_finishComponent()){comp.statusChanged.connect(_finishComponent)
}}}