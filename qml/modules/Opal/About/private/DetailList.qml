//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.2
import Sailfish.Silica 1.0
BackgroundItem{id:root
property string label
property var values
property bool activeLastValue:false
enabled:activeLastValue
width:parent.width
height:column.height
Column{id:column
width:parent.width
spacing:0
Repeater{model:values.length
delegate:DetailItem{label:index===0?root.label:""
value:root.values[index]
palette{secondaryHighlightColor:Theme.secondaryHighlightColor
highlightColor:(index===values.length-1&&activeLastValue)?(root.highlighted?Theme.secondaryHighlightColor:Theme.secondaryColor):Theme.highlightColor
}}}}}