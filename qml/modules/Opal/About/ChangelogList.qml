//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
QtObject{id:root
default property alias content:root.changelogItems
property list<ChangelogItem>changelogItems
readonly property int __is_opal_about_changelog_list:0
}