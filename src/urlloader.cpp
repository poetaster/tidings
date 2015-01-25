#include "urlloader.h"

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

UrlLoader::UrlLoader(QObject* parent)
    : QObject(parent)
    , myNetworkAccessManager(0)
    , myCurrentReply(0)
    , myIsLoading(false)
{
    myNetworkAccessManager = new QNetworkAccessManager(this);

    connect(myNetworkAccessManager,
            SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),
            this,
            SLOT(slotSslErrors(QNetworkReply*,QList<QSslError>)));
}

void UrlLoader::abort()
{
    if (myCurrentReply)
    {
        myCurrentReply->abort();
    }
}

void UrlLoader::setSource(const QUrl& source)
{
    abort();

    myIsLoading = false;
    emit loadingChanged();

    mySource = source;
    emit sourceChanged();

    myData.clear();
    emit dataChanged();

    if (source.isEmpty())
    {
        return;
    }

    myIsLoading = true;
    emit loadingChanged();

    QNetworkRequest req(source);
    req.setRawHeader("User-Agent",
                     QString("Tidings/%1 (Sailfish OS) "
                             "Mozilla/5.0 (Maemo; Linux; Jolla; Sailfish; Mobile) "
                             "AppleWebKit/534.13 (KHTML, like Gecko) "
                             "NokiaBrowser/8.5.0 Mobile Safari/534.13")
                     .arg(appVersion)
                     .toUtf8());

    qDebug() << "Requesting" << source;

    myCurrentReply = myNetworkAccessManager->get(req);
    connect(myCurrentReply, SIGNAL(finished()),
            this, SLOT(slotGotReply()));
}

void UrlLoader::slotSslErrors(QNetworkReply* reply,
                               const QList<QSslError>& errors)
{
    Q_UNUSED(errors)
    // don't care about SSL errors, such as self-signed certificates, etc.
    reply->ignoreSslErrors();
}

void UrlLoader::slotGotReply()
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
        myData = reply->readAll();
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
