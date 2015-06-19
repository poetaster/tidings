#ifndef HTMLFILTER_H
#define HTMLFILTER_H

#include <QFutureWatcher>
#include <QObject>
#include <QString>
#include <QStringList>

class HtmlFilter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
    Q_PROPERTY(QString imageProxy READ imageProxy WRITE setImageProxy NOTIFY imageProxyChanged)
    Q_PROPERTY(QString html READ html WRITE setHtml NOTIFY htmlChanged)
    Q_PROPERTY(QString htmlFiltered READ htmlFiltered NOTIFY filtered)
    Q_PROPERTY(QStringList images READ images NOTIFY imagesChanged)
public:
    explicit HtmlFilter(QObject* parent = 0);

    QPair<QString, QStringList> filter(const QString& html,
                                       const QString& url,
                                       const QString& imagePlaceHolder = QString()) const;

signals:
    void busyChanged();
    void baseUrlChanged();
    void imageProxyChanged();
    void htmlChanged();
    void filtered();
    void imagesChanged();

private slots:
    void slotFilteredFinished();

private:
    bool busy() const { return myIsBusy; }

    QString baseUrl() const { return myBaseUrl; }
    void setBaseUrl(const QString& baseUrl);

    QString imageProxy() const { return myImageProxy; }
    void setImageProxy(const QString& imageProxy);

    QString html() const { return myHtml; }
    void setHtml(const QString& html);

    QString htmlFiltered() const { return myHtmlFiltered; }

    QStringList images() const { return myImages; }

    void process();

private:
    bool myIsBusy;
    bool myProcessingRequested;
    QString myBaseUrl;
    QString myImageProxy;
    QString myHtml;
    QString myHtmlFiltered;
    QStringList myImages;

    QFutureWatcher<QPair<QString, QStringList> > myFilteredFutureWatcher;
};

#endif // HTMLFILTER_H
