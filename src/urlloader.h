#ifndef URLLOADER_H
#define URLLOADER_H

#include <QList>
#include <QObject>
#include <QSslError>
#include <QString>
#include <QUrl>

class QNetworkAccessManager;
class QNetworkReply;

class UrlLoader : public QObject
{
    Q_OBJECT
    Q_ENUMS(FeedType)
    Q_PROPERTY(QUrl source READ source WRITE setSource
               NOTIFY sourceChanged)
    Q_PROPERTY(QString destination READ destination WRITE setDestination
               NOTIFY destinationChanged)
    Q_PROPERTY(QString data READ data NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit UrlLoader(QObject* parent = 0);

    Q_INVOKABLE void abort();

    Q_INVOKABLE QString galleryPath(const QString& name);

signals:
    void sourceChanged();
    void destinationChanged();
    void dataChanged();
    void loadingChanged();
    void success();
    void error(const QString& details);

private:
    QUrl source() const { return mySource; }
    void setSource(const QUrl& source);

    QString destination() const { return myDestination; }
    void setDestination(const QString& destination);

    QString data() const { return myData; }

    bool loading() const { return myIsLoading; }

    void readData(QNetworkReply* reply);

private slots:
    void slotSslErrors(QNetworkReply* reply, const QList<QSslError>& errors);
    void slotGotReply();

private:
    QNetworkAccessManager* myNetworkAccessManager;
    QNetworkReply* myCurrentReply;

    QUrl mySource;
    QString myDestination;
    QString myData;
    bool myIsLoading;
};

#endif // URLLOADER_H
