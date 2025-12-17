//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
QtObject{id:root
property string spdxId
property string customShortText:""
readonly property bool error:__error
readonly property string name:__name
readonly property string fullText:__fullText
property bool __online:false
property string __localUrl:"%1/%2.json".arg(StandardPaths.temporary).arg(spdxId)
property string __remoteUrl:"https://spdx.org/licenses/%1.json".arg(spdxId)
property string __name:""
property string __fullText:""
property bool __error:false
property bool __initialized:false
property WorkerScript __worker:WorkerScript{source:"private/worker_spdx.js"
onMessage:{if(messageObject.spdxId!==spdxId)return
__name=messageObject.name
__fullText=messageObject.fullText
__error=messageObject.error
if(customShortText==="")customShortText=messageObject.shortText
}Component.onCompleted:{_load()
__initialized=true
}}
onSpdxIdChanged:{if(__initialized)_load(true)
}on__OnlineChanged:{_load()
}function _load(force){if(fullText!==""&&force!==true)return
if(spdxId===undefined||spdxId===""){__error=true
console.error("[Opal.About] cannot load license without spdxId")
return
}__name=""
__fullText=""
__error=false
__worker.sendMessage({spdxId:spdxId,localUrl:__localUrl,remoteUrl:__remoteUrl,shortText:customShortText,online:!!__online})
}}