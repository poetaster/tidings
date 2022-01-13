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
    // The new location of the LocalStorage database
    QDir newDbDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/de.poetaster/harbour-tidings/");

    if(newDbDir.exists())
        return;

    newDbDir.mkpath(newDbDir.path());

    QString pathOld = "/harbour-tidings/harbour-tidings/";
    QString pathNew = "/de.poetaster/harbour-tidings/";

    // The old LocalStorage database
    QFile oldDb(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) +  pathOld + "database.sqlite");
    oldDb.copy(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) +  pathNew + "database.sqlite");
    // proof of concept you can just move.
    //oldDb.rename(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) +  pathNew + dbname + ".sqlite");

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

    app->setOrganizationDomain("de.poetaster");
    app->setOrganizationName("de.poetaster"); // needed for Sailjail
    app->setApplicationName("harbour-tidings");

    migrateLocalStorage();

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
