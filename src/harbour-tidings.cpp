#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

#include <QDir>
#include <QGuiApplication>
#include <QLocale>
#include <QQuickView>
#include <QScopedPointer>
#include <QStandardPaths>
#include <QString>
#include <QStringList>
#include <QTranslator>
#include <QtQml>
#include <QDebug>

#include "appversion.h"
#include "database.h"
#include "dateparser.h"
#include "feedloader.h"
#include "htmlfilter.h"
#include "json.h"
#include "newsblendmodel.h"
#include "urlloader.h"


void migrateLocalStorage()
{
    // first for the new directory, post sailjail

    QDir newDbDir( QDir::homePath() + "/.local/share/de.poetaster/harbour-tidings/");

    if( ! newDbDir.exists() )
        newDbDir.mkpath(newDbDir.path());

    const QStringList dataPaths = QStandardPaths::standardLocations(
                QStandardPaths::DataLocation);

    foreach (const QString& path, dataPaths)
    {
        qDebug() << "Looking for database in" << path;
        const QString defaultDatabase(QDir(path).absoluteFilePath("database.sqlite"));
        if (QFile(defaultDatabase).exists())
        {

            qDebug() << "found old database " << defaultDatabase;

            // copy to new location if it's not there already.
            if ( ! QFile(newDbDir.absoluteFilePath("database.sqlite")).exists() )
            {
                // the GenericDataLocation mechanism :) I should probably do this everywhere.
                QFile(defaultDatabase).copy(
                            QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation )
                            + "/de.poetaster/harbour-tidings/database.sqlite" );
            }

        }
    }
}

/* Clears the web cache, because Qt 5.2 WebView chokes on caches from
 * older Qt versions.
 */
void clearWebCache()
{
    const QStringList cachePaths = QStandardPaths::standardLocations(
                QStandardPaths::CacheLocation);

    if (cachePaths.size())
    {
        // some very old versions of SailfishOS may not find this cache,
        // but that's OK since they don't have the web cache bug anyway
        const QString tidingsWebCache =
                QDir(cachePaths.at(0)).filePath(".QtWebKit");
        QDir cacheDir(tidingsWebCache);
        if (cacheDir.exists())
        {
            if (cacheDir.removeRecursively())
            {
                qDebug() << "Cleared web cache:" << tidingsWebCache;
            }
            else
            {
                qDebug() << "Failed to clear web cache:" << tidingsWebCache;
            }
        }
        else
        {
            qDebug() << "Web cache does not exist:" << tidingsWebCache;
        }
    }
    else
    {
        qDebug() << "No web cache available.";
    }
}

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/template.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    clearWebCache();

    app->setApplicationName("harbour-tidings");

    // first set too old OrgName
    // BEGIN HACK. It will need to be removed before we go Sailjail, proper
    //app->setOrganizationName("harbour-tidings");
    //migrateLocalStorage();
    // END HACK

    // now set too new OrgName
    app->setOrganizationDomain("de.poetaster");
    app->setOrganizationName("de.poetaster"); // needed for Sailjail

    QTranslator *appTranslator = new QTranslator;
    appTranslator->load("harbour-tidings-" + QLocale::system().name(), SailfishApp::pathTo("translations").path());
    app->installTranslator(appTranslator);

    qmlRegisterType<Database>("harbour.tidings", 1, 0, "Database");
    qmlRegisterType<FeedLoader>("harbour.tidings", 1, 0, "FeedLoader");
    qmlRegisterType<HtmlFilter>("harbour.tidings", 1, 0, "HtmlFilter");
    qmlRegisterType<UrlLoader>("harbour.tidings", 1, 0, "UrlLoader");
    qmlRegisterType<NewsBlendModel>("harbour.tidings", 1, 0, "NewsModel");

    DateParser dateParser;
    Json json;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty("appVersion", appVersion);
    view->rootContext()->setContextProperty("dateParser", &dateParser);
    view->rootContext()->setContextProperty("json", &json);

    view->setSource(SailfishApp::pathTo("qml/harbour-tidings.qml"));
    view->setTitle("Tidings");
    view->showFullScreen();

    return app->exec();
}
