//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2023 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import"private/functions.js"as Func
QtObject{property string version
property date date:new Date(NaN)
property string author
property var paragraphs
property int textFormat:Text.StyledText
property var __effectiveEntries:Func.makeStringList(paragraphs,false)
property string __effectiveSection:version+(isNaN(date.valueOf())?"":"|"+Qt.formatDate(date,Qt.DefaultLocaleShortDate))
}