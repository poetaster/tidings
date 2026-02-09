#ifndef DATEPARSER_H
#define DATEPARSER_H

#include <QObject>
#include <QDateTime>
#include <QString>
#include <QDebug>

#include <locale.h>
#include <time.h>

class DateParser : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QDateTime parse(const QString& dateString) const
    {
        // Qt::RFC2822Date is not supported by Qt < 5.2, so we have to break compatibility
        // with ancient SFOS versions. A reliable custom implementation would be hard.
        QDateTime d = QDateTime::fromString(dateString, Qt::RFC2822Date);

        if (! d.isValid())
        {
            d = QDateTime::fromString(dateString, Qt::ISODate);
        }

        //qDebug() << "Parsing date:" << dateString << "->" << d;
        return d;
    }
};

#endif // DATEPARSER_H
