//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import".."
Page{id:root
property list<ContributionSection>sections
property list<Attribution>attributions
property var mainAttributions:[]
property string appName
property bool allowDownloadingLicenses:false
property bool autoAddOpalAttributions:false
allowedOrientations:Orientation.All
OpalAttributionsLoader{id:opalAttributions
enabled:autoAddOpalAttributions
}SilicaFlickable{anchors.fill:parent
contentHeight:column.height+2*Theme.paddingLarge
VerticalScrollDecorator{}Column{id:column
width:parent.width
spacing:Theme.paddingMedium
PageHeader{title:qsTranslate("Opal.About","Contributors")
}SectionHeader{text:qsTranslate("Opal.About","Development")
visible:mainAttributions.length>0
}DetailList{visible:mainAttributions.length>0
label:appName
values:mainAttributions
}Repeater{model:sections
delegate:Column{width:parent.width
spacing:column.spacing
SectionHeader{text:modelData.title
visible:modelData.title!==""&&modelData.groups.length>0&&!(index===0&&(modelData.title==="Development"||modelData.title===qsTranslate("Opal.About","Development")))
}Repeater{model:modelData.groups
delegate:DetailList{label:modelData.title
values:modelData.__effectiveEntries
}}}}Column{width:parent.width
spacing:column.spacing
SectionHeader{text:qsTranslate("Opal.About","Acknowledgements")
visible:attributions.length>0||opalAttributions.loadedAttributions.length>0
}ContributorsAttributionRepeater{model:attributions
}ContributorsAttributionRepeater{model:opalAttributions.loadedAttributions
}}}}}