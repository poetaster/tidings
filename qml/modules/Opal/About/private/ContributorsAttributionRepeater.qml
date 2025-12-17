//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import"functions.js"as Func
Repeater{delegate:DetailList{property string spdxString:modelData._getSpdxString(" • • •")
property bool showLicensePage:false
activeLastValue:spdxString!==""||modelData.sources!==""||modelData.homepage!==""||modelData.description!==""
label:(modelData.__effectiveEntries.length===0&&spdxString==="")?qsTranslate("Opal.About","Thank you!"):modelData.name
values:{var vals=Func.makeStringListConcat(modelData.__effectiveEntries,spdxString,false)
if(vals.length===0){vals=[modelData.name]
}if(spdxString===""){var append=""
if(modelData.description!==""||(modelData.sources!==""&&modelData.homepage!=="")){append=qsTranslate("Opal.About","Details")
if(modelData.description!==""){showLicensePage=true
}}else if(modelData.sources!==""){append=qsTranslate("Opal.About","Source Code")
}else if(modelData.homepage!==""){append=qsTranslate("Opal.About","Homepage")
}if(append!==""){vals.push(append+"  • • •")
}}else{showLicensePage=true
}return vals
}onClicked:{if(showLicensePage){pageStack.animatorPush("LicensePage.qml",{"mainAttribution":modelData,"attributions":[],"allowDownloadingLicenses":allowDownloadingLicenses,"enableSourceHint":true})
}else{var urls=[]
if(modelData.homepage!==""){urls.push({externalUrl:modelData.homepage,title:qsTranslate("Opal.About","Homepage")})
}if(modelData.sources!==""){urls.push({externalUrl:modelData.sources,title:qsTranslate("Opal.About","Source Code")})
}L.LinkHandler.openOrCopyMultipleUrls(urls)
}}}}