//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.0
import Sailfish.Silica 1.0
Repeater{id:root
property bool initiallyExpanded
property string mainModule
delegate:LicenseListPart{title:modelData.name
headerVisible:title!==""&&title!==mainModule
licenses:modelData.licenses
extraTexts:modelData.__effectiveEntries
description:modelData.description
initiallyExpanded:root.initiallyExpanded
homepage:modelData.homepage
sources:modelData.sources
}}