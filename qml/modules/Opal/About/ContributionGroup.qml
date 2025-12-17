//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import"private/functions.js"as Func
QtObject{property string title
property var entries:[]
property var __effectiveEntries:Func.makeStringList(entries)
}