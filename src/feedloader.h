#ifndef FEEDLOADER_H
#define FEEDLOADER_H

#include <QList>
#include <QObject>
#include <QSslError>
#include <QString>
#include <QUrl>

class QNetworkAccessManager;
class QNetworkReply;

class FeedLoader : public QObject
{
    Q_OBJECT
    Q_ENUMS(FeedType)
    Q_PROPERTY(QString source READ source WRITE setSource
               NOTIFY sourceChanged)
    Q_PROPERTY(FeedType type READ type NOTIFY dataChanged)
    Q_PROPERTY(QUrl logo READ logo NOTIFY dataChanged)
    Q_PROPERTY(QString data READ data NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    enum FeedType
    {
        RSS2,
        RDF,
        Atom,
        OPML,
        Unknown
    };
    explicit FeedLoader(QObject* parent = 0);

    Q_INVOKABLE void abort();

signals:
    void sourceChanged();
    void dataChanged();
    void loadingChanged();
    void success();
    void error(const QString& details);

private:
    QString source() const { return mySource; }
    void setSource(const QString& source);

    FeedType type() const { return myType; }
    QUrl logo() const { return myLogo; }
    QString data() const { return myData; }

    bool loading() const { return myIsLoading; }

    void analyzeFeed();

private slots:
    void slotSslErrors(QNetworkReply* reply, const QList<QSslError>& errors);
    void slotGotReply();

private:
    QNetworkAccessManager* myNetworkAccessManager;
    QNetworkReply* myCurrentReply;

    QString mySource;
    QString myData;
    bool myIsLoading;
    FeedType myType;
    QUrl myLogo;
};

#endif // FEEDLOADER_H
