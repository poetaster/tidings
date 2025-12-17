//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
import"../LinkHandler"as L
import"private/functions.js"as Func
import"private"
Page{id:page
property string appName:""
property string appIcon:""
property string appVersion:""
property string appRelease:"1"
property string appReleaseType:""
property string description:""
property var mainAttributions:[]
property var authors:[]
property var __effectiveMainAttribs:Func.makeStringListConcat(authors,mainAttributions,false)
property string sourcesUrl:""
property string translationsUrl:""
property string homepageUrl:""
property list<ChangelogItem>changelogItems
property url changelogList
property list<License>licenses
property bool allowDownloadingLicenses:false
property list<Attribution>attributions
property bool autoAddOpalAttributions:true
readonly property DonationsGroup donations:DonationsGroup{}
property list<InfoSection>extraSections
property list<ContributionSection>contributionSections
property alias flickable:_flickable
property alias _pageHeaderItem:_pageHeader
property alias _iconItem:_icon
property alias _develInfoSection:_develInfo
property alias _licenseInfoSection:_licenseInfo
property alias _donationsInfoSection:_donationsInfo
readonly property Attribution _effectiveSelfAttribution:Attribution{name:appName
entries:__effectiveMainAttribs
licenses:page.licenses
homepage:homepageUrl
sources:sourcesUrl
}
function openOrCopyUrl(externalUrl,title){L.LinkHandler.openOrCopyUrl(externalUrl,title)
}allowedOrientations:Orientation.All
SilicaFlickable{id:_flickable
contentHeight:column.height
anchors.fill:parent
VerticalScrollDecorator{}onContentHeightChanged:{if(_flickable.contentHeight>page.height&&_flickable.contentHeight-_pageHeader.origHeight+Theme.paddingMedium<page.height){var to=(page.height-(_flickable.contentHeight-_pageHeader.origHeight))/2+Theme.paddingMedium
if(to<paddingAnim.to)paddingAnim.to=to
hideAnim.restart()
}}Column{id:column
width:parent.width
spacing:1.5*Theme.paddingLarge
PageHeader{id:_pageHeader
property real origHeight:height
title:qsTranslate("Opal.About","About")
Component.onCompleted:origHeight=height
ParallelAnimation{id:hideAnim
FadeAnimator{target:_pageHeader
to:0.0
duration:80
}SmoothedAnimation{id:paddingAnim
target:_pageHeader
property:"height"
to:_pageHeader.origHeight
duration:80
}}}Image{id:_icon
anchors.horizontalCenter:parent.horizontalCenter
width:Theme.itemSizeExtraLarge
height:Theme.itemSizeExtraLarge
fillMode:Image.PreserveAspectFit
source:appIcon
verticalAlignment:Image.AlignVCenter
}Column{width:parent.width-2*Theme.horizontalPageMargin
anchors.horizontalCenter:parent.horizontalCenter
spacing:Theme.paddingSmall
Label{width:parent.width
visible:appName!==""
text:appName
color:Theme.highlightColor
font.pixelSize:Theme.fontSizeLarge
horizontalAlignment:Text.AlignHCenter
}Label{width:parent.width
visible:String(appVersion)!==""
text:qsTranslate("Opal.About","Version %1").arg(Func.formatAppVersion(appVersion,appRelease,appReleaseType))
wrapMode:Text.Wrap
color:Theme.secondaryHighlightColor
font.pixelSize:Theme.fontSizeMedium
horizontalAlignment:Text.AlignHCenter
}}Label{anchors.horizontalCenter:parent.horizontalCenter
width:parent.width-2*Theme.horizontalPageMargin
text:description
onLinkActivated:openOrCopyUrl(link)
wrapMode:Text.Wrap
textFormat:Text.StyledText
horizontalAlignment:Text.AlignHCenter
linkColor:palette.secondaryColor
palette.primaryColor:Theme.highlightColor
}InfoSection{id:_develInfo
width:parent.width
title:qsTranslate("Opal.About","Development")
enabled:autoAddOpalAttributions||contributionSections.length>0||attributions.length>0
text:__effectiveMainAttribs.join(", ")
showMoreLabel:qsTranslate("Opal.About","show contributors")
onClicked:{pageStack.animatorPush("private/ContributorsPage.qml",{"appName":appName,"sections":contributionSections,"attributions":attributions,"mainAttributions":__effectiveMainAttribs,"allowDownloadingLicenses":allowDownloadingLicenses,"autoAddOpalAttributions":autoAddOpalAttributions})
}buttons:[InfoButton{text:qsTranslate("Opal.About","Homepage")
onClicked:openOrCopyUrl(homepageUrl,text)
enabled:homepageUrl!==""
},InfoButton{text:qsTranslate("Opal.About","Changelog")
onClicked:pageStack.animatorPush(Qt.resolvedUrl("private/ChangelogPage.qml"),{appName:appName,changelogItems:changelogItems,changelogList:changelogList})
enabled:changelogItems.length>0||changelogList!=""
},InfoButton{text:qsTranslate("Opal.About","Translations")
onClicked:openOrCopyUrl(translationsUrl,text)
enabled:translationsUrl!==""
},InfoButton{text:qsTranslate("Opal.About","Source Code")
onClicked:openOrCopyUrl(sourcesUrl,text)
enabled:sourcesUrl!==""
}]}Column{width:parent.width
spacing:parent.spacing
children:extraSections
}InfoSection{id:_donationsInfo
visible:donations.services.length>0||donations.text!==""
width:parent.width
title:qsTranslate("Opal.About","Donations")
enabled:false
text:donations.text===""?donations.defaultTextGeneral:donations.text
__donationButtons:donations.services
}InfoSection{id:_licenseInfo
width:parent.width
title:qsTranslate("Opal.About","License")
enabled:licenses.length>0
onClicked:pageStack.animatorPush("private/LicensePage.qml",{"mainAttribution":_effectiveSelfAttribution,"attributions":attributions,"allowDownloadingLicenses":allowDownloadingLicenses,"enableSourceHint":true,"includeOpal":autoAddOpalAttributions})
text:enabled===false?"This component has been improperly configured. Please report this bug.":((licenses[0].name!==""&&licenses[0].error!==true)?licenses[0].name:licenses[0].spdxId)
smallPrint:licenses[0].customShortText
showMoreLabel:qsTranslate("Opal.About","show license(s)","",licenses.length+attributions.length)
clip:true
Behavior on height{SmoothedAnimation{duration:80
}}}Item{id:bottomVerticalSpacing
width:parent.width
height:Theme.paddingMedium
}}}Component.onCompleted:{if(__silica_applicationwindow_instance&&__silica_applicationwindow_instance.hasOwnProperty("_defaultPageOrientations")){__silica_applicationwindow_instance._defaultPageOrientations=Orientation.All
}}}