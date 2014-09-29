#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

#include <QGuiApplication>
#include <QLocale>
#include <QQuickView>
#include <QScopedPointer>
#include <QTranslator>
#include <QtQml>

#include "appversion.h"
#include "feedloader.h"
#include "htmlfilter.h"
#include "json.h"
#include "newsblendmodel.h"

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

    QTranslator *appTranslator = new QTranslator;
    appTranslator->load("harbour-tidings-" + QLocale::system().name(), SailfishApp::pathTo("translations").path());
    app->installTranslator(appTranslator);

    qmlRegisterType<FeedLoader>("harbour.tidings", 1, 0, "FeedLoader");
    qmlRegisterType<NewsBlendModel>("harbour.tidings", 1, 0, "NewsModel");

    HtmlFilter htmlFilter;
    Json json;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty("appVersion", appVersion);
    view->rootContext()->setContextProperty("htmlFilter", &htmlFilter);
    view->rootContext()->setContextProperty("json", &json);

    view->setSource(SailfishApp::pathTo("qml/harbour-tidings.qml"));
    view->setTitle("Tidings");
    view->showFullScreen();

    return app->exec();
}
