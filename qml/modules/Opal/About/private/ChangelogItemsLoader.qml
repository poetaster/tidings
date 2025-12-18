//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import".."
Loader{id:root
property list<ChangelogItem>changelogItems
property url changelogList
property list<ChangelogItem>effectiveItems
asynchronous:true
source:changelogList
onStatusChanged:{if(status===Loader.Ready){if(!item.hasOwnProperty("__is_opal_about_changelog_list")||!item.hasOwnProperty("changelogItems")){console.error("[Opal.About] programming error: changelogList must be "+"a reference to a valid ChangelogList component")
}else{effectiveItems=item.changelogItems
}}}Component.onCompleted:{if(changelogItems.length>0){if(changelogList!=""){console.error("[Opal.About] programming error: it is not allowed to define "+"both changelogItems and changelogList. Changelog items in "+"the changelog list '%1' will not be shown.".arg(changelogList))
changelogList=""
}effectiveItems=changelogItems
}}}