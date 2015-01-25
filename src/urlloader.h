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
    Q_PROPERTY(QString data READ data NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit UrlLoader(QObject* parent = 0);

    Q_INVOKABLE void abort();

signals:
    void sourceChanged();
    void dataChanged();
    void loadingChanged();
    void success();
    void error(const QString& details);

private:
    QUrl source() const { return mySource; }
    void setSource(const QUrl& source);

    QString data() const { return myData; }

    bool loading() const { return myIsLoading; }

private slots:
    void slotSslErrors(QNetworkReply* reply, const QList<QSslError>& errors);
    void slotGotReply();

private:
    QNetworkAccessManager* myNetworkAccessManager;
    QNetworkReply* myCurrentReply;

    QUrl mySource;
    QString myData;
    bool myIsLoading;
};

#endif // URLLOADER_H
