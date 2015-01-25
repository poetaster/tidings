#ifndef HTMLFILTER_H
#define HTMLFILTER_H

#include <QObject>
#include <QString>
#include <QStringList>

class HtmlFilter : public QObject
{
    Q_OBJECT
public:
    explicit HtmlFilter(QObject* parent = 0);

    Q_INVOKABLE QString filter(const QString& html, const QString& url) const;
    Q_INVOKABLE QStringList getImages(const QString& html) const;
};

#endif // HTMLFILTER_H
