//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
import".."
Page{id:root
property string appName
property alias changelogItems:view.changelogItems
property alias changelogList:view.changelogList
property alias scrollbarType:view.scrollbarType
allowedOrientations:Orientation.All
ChangelogView{id:view
anchors.fill:parent
header:PageHeader{title:qsTranslate("Opal.About","Changelog")
description:appName
}}}