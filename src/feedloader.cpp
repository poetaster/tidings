#include "feedloader.h"
#include "appversion.h"

#include <QDomDocument>
#include <QDomElement>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QStringList>

#include <QDebug>

namespace
{

QString nodeText(const QDomNode& node, QStringList path, bool& exists)
{
    if (path.isEmpty())
    {
        if (node.isElement())
        {
            exists = true;
            return node.toElement().text();
        }
        else
        {
            exists = false;
            return QString();
        }
    }

    const QString pathItem = path.first();

    QDomNodeList childNodes = node.childNodes();
    for (int i = 0; i < childNodes.size(); ++i)
    {
        QDomNode childNode = childNodes.at(i);
        if (childNode.isElement() && childNode.toElement().tagName() == pathItem)
        {
            return nodeText(childNode, path.mid(1), exists);
        }
    }
    exists = false;
    return QString();
}

}

FeedLoader::FeedLoader(QObject* parent)
    : QObject(parent)
    , myNetworkAccessManager(0)
    , myCurrentReply(0)
    , myIsLoading(false)
    , myType(Unknown)
{
    myNetworkAccessManager = new QNetworkAccessManager(this);

    connect(myNetworkAccessManager,
            SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),
            this,
            SLOT(slotSslErrors(QNetworkReply*,QList<QSslError>)));
}

void FeedLoader::abort()
{
    if (myCurrentReply)
    {
        myCurrentReply->abort();
    }
}

void FeedLoader::setSource(const QString& source)
{
    abort();

    mySource = source;
    emit sourceChanged();

    myIsLoading = true;
    emit loadingChanged();

    myData.clear();
    myType = Unknown;
    myLogo.clear();
    emit dataChanged();

    QNetworkRequest req(source);
    req.setRawHeader("User-Agent",
                     QString("Tidings/%1 (Sailfish OS)")
                     .arg(appVersion)
                     .toUtf8());

    qDebug() << "Requesting" << source;

    myCurrentReply = myNetworkAccessManager->get(req);
    connect(myCurrentReply, SIGNAL(finished()),
            this, SLOT(slotGotReply()));
}

void FeedLoader::analyzeFeed()
{
    if (myData.isEmpty())
    {
        return;
    }

    QDomDocument doc;
    doc.setContent(myData, true);
    QDomElement root = doc.firstChildElement();

    qDebug() << "root" << root.tagName();
    if (root.tagName() == "rss")
    {
        bool exists = false;
        myLogo = QUrl(nodeText(root, QStringList() << "channel" << "image" << "url", exists));
        if (myLogo.isEmpty())
        {
            myLogo = QUrl(nodeText(root, QStringList() << "channel"  << "icon", exists));
        }
        myType = RSS2; // and also the RSS 0.9x family
        qDebug() << "logo exists" << exists << myLogo;
    }
    else if (root.tagName() == "RDF")
    {
        myType = RDF; // aka RSS 1.0
    }
    else if (root.tagName() == "feed")
    {
        myType = Atom;
    }
    else if (root.tagName() == "opml")
    {
        myType = OPML;
    }
}

void FeedLoader::slotSslErrors(QNetworkReply* reply,
                               const QList<QSslError>& errors)
{
    Q_UNUSED(errors)
    // don't care about SSL errors, such as self-signed certificates, etc.
    reply->ignoreSslErrors();
}

void FeedLoader::slotGotReply()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    myCurrentReply = 0;

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
            myCurrentReply = myNetworkAccessManager->get(req);
            connect(myCurrentReply, SIGNAL(finished()),
                    this, SLOT(slotGotReply()));
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
        analyzeFeed();

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
