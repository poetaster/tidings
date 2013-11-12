# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = tidings

CONFIG += sailfishapp

SOURCES += src/tidings.cpp

OTHER_FILES += qml/tidings.qml \
    qml/cover/CoverPage.qml \
    rpm/tidings.spec \
    rpm/tidings.yaml \
    tidings.desktop \
    qml/pages/FeedsPage.qml \
    qml/pages/RssModel.qml \
    qml/pages/SourcesPage.qml \
    qml/pages/AtomModel.qml \
    qml/pages/OpmlModel.qml \
    qml/pages/ViewPage.qml \
    qml/pages/WebPage.qml \
    qml/pages/FavIcon.qml \
    qml/pages/favicon.js \
    qml/pages/database.js \
    qml/pages/SourcesModel.qml \
    qml/pages/SourceEditDialog.qml \
    qml/pages/NewsBlendModel.qml \
    qml/pages/AboutPage.qml \
    qml/pages/LicensePage.qml \
    qml/pages/license.js \
    qml/tidings.png

TRANSLATIONS = l10n/en_US.ts

lupdate_only{
SOURCES = qml/tidings.qml \
          qml/pages/*.qml \
          qml/cover/*.qml
}

RESOURCES += \
    resources.qrc
