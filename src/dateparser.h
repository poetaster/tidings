#ifndef DATEPARSER_H
#define DATEPARSER_H

#include <QObject>
#include <QDateTime>
#include <QString>
#include <QDebug>

class DateParser : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QDateTime parse(const QString& dateString) const
    {
        QDateTime d = QDateTime::fromString(dateString, Qt::RFC2822Date);
        if (! d.isValid())
        {
            d = QDateTime::fromString(dateString, Qt::ISODate);
        }
        qDebug() << "Parsing date:" << dateString << "->" << d;
        return d;
    }
};

#endif // DATEPARSER_H
