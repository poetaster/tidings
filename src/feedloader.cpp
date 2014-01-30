#include "feedloader.h"
#include "appversion.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QDomDocument>
#include <QDomElement>

#include <QDebug>

FeedLoader::FeedLoader(QObject* parent)
    : QObject(parent)
    , myNetworkAccessManager(0)
    , myIsLoading(false)
{
    myNetworkAccessManager = new QNetworkAccessManager(this);

    connect(myNetworkAccessManager,
            SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>&)),
            this,
            SLOT(slotSslErrors(QNetworkReply*,QList<QSslError>)));
    connect(myNetworkAccessManager, SIGNAL(finished(QNetworkReply*)),
            this, SLOT(slotGotReply(QNetworkReply*)));
}

void FeedLoader::setSource(const QUrl& source)
{
    mySource = source;
    emit sourceChanged();

    myIsLoading = true;
    emit loadingChanged();

    myData.clear();
    emit dataChanged();

    QNetworkRequest req(source);
    req.setRawHeader("User-Agent",
                     QString("Tidings/%1 (Sailfish OS)")
                     .arg(appVersion)
                     .toUtf8());

    qDebug() << "Requesting" << source;

    myNetworkAccessManager->get(req);
}

FeedLoader::FeedType FeedLoader::type() const
{
    if (myData.isEmpty())
    {
        return Unknown;
    }

    QDomDocument doc;
    doc.setContent(myData, true);
    QDomElement root = doc.firstChildElement();

    qDebug() << "root" << root.tagName();
    if (root.tagName() == "rss")
    {
        return RSS2; // and also the RSS 0.9x family
    }
    else if (root.tagName() == "RDF")
    {
        return RDF; // aka RSS 1.0
    }
    else if (root.tagName() == "feed")
    {
        return Atom;
    }
    else if (root.tagName() == "opml")
    {
        return OPML;
    }
    else
    {
        return Unknown;
    }


}

void FeedLoader::slotSslErrors(QNetworkReply* reply,
                               const QList<QSslError>& errors)
{
    Q_UNUSED(errors)
    // don't care about SSL errors, such as self-signed certificates, etc.
    reply->ignoreSslErrors();
}

void FeedLoader::slotGotReply(QNetworkReply* reply)
{
    int httpCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    qDebug() << "Receiving"
             << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()
             << reply->request().url();
    qDebug() << reply->rawHeaderPairs();

    // handle redirections
    QVariant redirectUrl = reply->attribute(
                QNetworkRequest::RedirectionTargetAttribute);
    if (redirectUrl.isValid())
    {
        QUrl currentLocation = reply->request().url();
        QUrl newLocation = redirectUrl.toUrl();
        if (newLocation.isRelative())
        {
            newLocation = currentLocation.resolved(newLocation);
        }
        if (currentLocation != newLocation)
        {
            qDebug() << "Redirected to " << newLocation;
            QNetworkRequest req(newLocation);
            req.setRawHeader("User-Agent",
                             QString("Tidings/%1 (Sailfish OS)")
                             .arg(appVersion)
                             .toUtf8());
            myNetworkAccessManager->get(req);
        }
        else
        {
            qDebug() << "Redirection loop detected.";
            emit error("Redirection loop detected.");
            myIsLoading = false;
            emit loadingChanged();
        }

        reply->deleteLater();
        return;
    }

    switch (reply->error())
    {
    case QNetworkReply::NoError:
    {
        qDebug() << "parsing now";
        // XmlListModel expects UTF-8 encoded data in its 'xml' property,
        // but still applies the XML document encoding, which is wrong,
        // so convert from encoding to UTF-8 here, and remove the 'encoding'
        // information

        // convert from encoding to UTF-8
        QDomDocument doc;
        doc.setContent(reply->readAll(), false);
        QString data = doc.toString();

        // remove <?xml ... ?> instructions
        if (data.startsWith("<?"))
        {
            int idx = data.indexOf("?>");
            if (idx != -1)
            {
                data = data.mid(idx + 3);
            }
        }

        // force UTF-8 for encoding
        myData = "<?xml version='1.0' encoding='UTF-8'?>" + data;
        qDebug() << myData.size() << "bytes";
        qDebug() << myData.left(1024);
        emit dataChanged();
        emit success();
        break;
    }

    default:
        qDebug() << "Network Error" << reply->error() << reply->errorString();
        emit error(reply->errorString());
        break;
    }

    reply->deleteLater();
    myIsLoading = false;
    emit loadingChanged();
}
