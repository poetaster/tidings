#ifndef JSON_H
#define JSON_H

#include <QObject>
#include <QJsonDocument>
#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <QDebug>

class Json : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QString toJson(const QVariant& obj) const
    {
        // reduce amount of data to save
        QVariantMap map = obj.toMap();
        foreach (const QString& key, map.keys())
        {
            if (map.value(key).toString().isEmpty())
            {
                map.remove(key);
            }
        }

        QJsonDocument doc = QJsonDocument::fromVariant(map);
        return QString::fromUtf8(doc.toJson());
    }

    Q_INVOKABLE QVariantMap fromJson(const QString& data) const
    {
        QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
        return doc.toVariant().toMap();
    }
};

#endif // JSON_H
