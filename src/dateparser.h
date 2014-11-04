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
        QDateTime d;
        if (dateString.contains(","))
        {
            // Qt::RFC2822Date is not supported by Qt < 5.2, so re-implement it
            // to stay backwards compatible
            struct tm tm;
            setlocale(LC_TIME, "C");
            strptime(dateString.toLatin1().constData(),
                     "%a, %d %b %Y %H:%M:%S %z",
                     &tm);
            setlocale(LC_TIME, "");
            d = QDateTime::fromTime_t(timegm(&tm));
        }

        if (! d.isValid())
        {
            d = QDateTime::fromString(dateString, Qt::ISODate);
        }

        qDebug() << "Parsing date:" << dateString << "->" << d;
        return d;
    }
};

#endif // DATEPARSER_H
