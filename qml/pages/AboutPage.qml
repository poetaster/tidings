/*
 * This file is part of harbour-tidings.
 * SPDX-FileCopyrightText: 2025 Mark Washeim
 * SPDX-FileCopyrightText: 2025 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/Opal/About"

AboutPageBase {
    id: root
    allowedOrientations: Orientation.All

    appName: "Tidings"
    appIcon: Qt.resolvedUrl("../tidings.png")
    appVersion: APP_VERSION
    appRelease: ""
    description: qsTr("A news feed and podcast aggregator.")
    sourcesUrl: "https://github.com/poetaster/tidings"
    // translationsUrl: "https://weblate.org/..."

    authors: [
        "2021 - %1 Mark Washeim".arg((new Date()).getFullYear()),
        "2013 - 2020 Martin Grimme"
    ]
    licenses: License { spdxId: "GPL-2.0-only" }

    /* changelogItems: [
        // add new items at the top of the list
        ChangelogItem {
            version: "1.0.0-1"
            date: "2023-01-02"  // optional
            author: "Au Thor"   // optional
            paragraphs: "A short paragraph describing this initial version."
        }
    ] */

    donations.text: donations.defaultTextCoffee
    donations.services: DonationService {
        name: "LiberaPay"
        url: "https://liberapay.com/poetaster"
    }

    /* attributions: [
        Attribution {
            name: "The Library"
            entries: ["1201 The Old Librarians", "2014 The Librarians"]
            licenses: License { spdxId: "CC0-1.0" }
        }
    ] */

    contributionSections: [
        ContributionSection {
            groups: [
                ContributionGroup {
                    title: qsTr("Programming")
                    entries: [
                        "Martin Grimme",
                        "Mark Washeim",
                        "Mirian Margiani",
                        "Joni Korhonen"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Icon Design")
                    entries: [
                        "Martin Grimme"
                    ]
                }
            ]
        },
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup {
                    title: qsTr("English")
                    entries: [
                        "Martin Grimme",
                        "Mark Washeim"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Czech")
                    entries: [
                        "Malakay"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Finnish")
                    entries: [
                        "Joni Korhonen"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Brazilian Portuguese")
                    entries: [
                        "caio2k"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Greek")
                    entries: [
                        "cquence"
                    ]
                },
                ContributionGroup {
                    title: qsTr("French")
                    entries: [
                        "Samuel Kay"
                    ]
                },
                ContributionGroup {
                    title: qsTr("Russian")
                    entries: [
                        "Вячеслав Диконов",
                        "coyote",
                        "equeim"
                    ]
                },
                ContributionGroup {
                    title: qsTr("German")
                    entries: [
                        "Christoph",
                        "Martin Grimme",
                        "Mark Washeim",
                        "pycage"
                    ]
                }
            ]
        }
    ]
}
