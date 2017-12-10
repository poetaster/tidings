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

            // non-numeric UTC offset representations
            QMap<QString, long int> timezones;
            timezones["Z"] = 0;  // "Zulu time" has been used as an nautical
                                 // alias to GMT since the 1950s
            timezones["UT"] = 0;
            timezones["GMT"] = 0;
            timezones["EST"] = -5 * 3600;
            timezones["EDT"] = -4 * 3600;
            timezones["CST"] = -6 * 3600;
            timezones["CDT"] = -5 * 3600;
            timezones["MST"] = -7 * 3600;
            timezones["MDT"] = -6 * 3600;
            timezones["PST"] = -8 * 3600;
            timezones["PDT"] = -7 * 3600;

            QStringList parts = dateString.split(' ');

            struct tm tm;
            setlocale(LC_TIME, "C");
            strptime(dateString.toLatin1().constData(),
                     "%a, %d %b %Y %H:%M:%S %z",
                     &tm);
            setlocale(LC_TIME, "");

            // get the offset to UTC
            long int utcOffset = timezones.value(parts.last(),
                                                 tm.tm_gmtoff);
            // treat time as UTC and correct timeshift by subtracting the offset
            d = QDateTime::fromTime_t(timegm(&tm) - utcOffset);
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
