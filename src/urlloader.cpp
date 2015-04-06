#include "urlloader.h"

#include "appversion.h"

#include <QDir>
#include <QDomDocument>
#include <QDomElement>
#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegExp>
#include <QStandardPaths>
#include <QStringList>
#include <QTextCodec>

#include <QDebug>

namespace
{

const QRegExp RE_CHARSET("charset\\s*=\\s*([a-zA-Z0-9\\-]+)");

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

QString getCharset(const QString& contentType)
{
    int pos = RE_CHARSET.indexIn(contentType);
    if (pos != -1)
    {
        return RE_CHARSET.cap(1);
    }
    else
    {
        return QString();
    }
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

QString UrlLoader::galleryPath(const QString& name)
{
    return QDir(QStandardPaths::writableLocation(
                    QStandardPaths::PicturesLocation)).absoluteFilePath(name);
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

void UrlLoader::setDestination(const QString& destination)
{
    myDestination = destination;
    emit destinationChanged();
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
        readData(reply);
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

void UrlLoader::readData(QNetworkReply* reply)
{
    if (myDestination.isEmpty())
    {
        const QByteArray data = reply->readAll();

        const QString charSet =
                getCharset(reply->header(QNetworkRequest::ContentTypeHeader)
                           .toString());

        qDebug() << "Character Set:" << charSet;
        if (charSet.size())
        {
            QTextCodec* codec = QTextCodec::codecForName(charSet.toLatin1());
            if (codec)
            {
                myData = codec->toUnicode(data);
            }
            else
            {
                myData = data;
            }
        }
        else
        {
            myData = data;
        }

        emit dataChanged();
        emit success();
    }
    else
    {
        QFile fd(myDestination);
        if (fd.open(QIODevice::WriteOnly))
        {
            while (! reply->atEnd())
            {
                fd.write(reply->read(0xffff));
            }
            emit success();
            qDebug() << "File saved to" << myDestination;
        }
        else
        {
            emit error(QString("Could not write file: %1").arg(myDestination));
        }
    }
}
