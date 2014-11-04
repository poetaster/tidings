/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
#include "dateparser.h"
#include "feedloader.h"
#include "htmlfilter.h"
#include "json.h"
#include "newsblendmodel.h"

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

    QTranslator *appTranslator = new QTranslator;
    appTranslator->load("harbour-tidings-" + QLocale::system().name(), SailfishApp::pathTo("translations").path());
    app->installTranslator(appTranslator);

    qmlRegisterType<FeedLoader>("harbour.tidings", 1, 0, "FeedLoader");
    qmlRegisterType<NewsBlendModel>("harbour.tidings", 1, 0, "NewsModel");

    DateParser dateParser;
    HtmlFilter htmlFilter;
    Json json;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty("appVersion", appVersion);
    view->rootContext()->setContextProperty("dateParser", &dateParser);
    view->rootContext()->setContextProperty("htmlFilter", &htmlFilter);
    view->rootContext()->setContextProperty("json", &json);

    view->setSource(SailfishApp::pathTo("qml/harbour-tidings.qml"));
    view->setTitle("Tidings");
    view->showFullScreen();

    return app->exec();
}
