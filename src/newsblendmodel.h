#ifndef NEWSBLENDMODEL_H
#define NEWSBLENDMODEL_H

#include <QAbstractListModel>
#include <QByteArray>
#include <QDateTime>
#include <QHash>
#include <QList>
#include <QMap>
#include <QObject>
#include <QPair>
#include <QVariant>
#include <QVariantMap>
#include <QSharedPointer>

class NewsBlendModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(SortMode)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode
               NOTIFY sortModeChanged)
public:
    struct Enclosure
    {
        QString url;
        QString mimeType;
        qint64 size;
    };

    struct Item
    {
        typedef QSharedPointer<Item> Ptr;
        typedef QSharedPointer<const Item> ConstPtr;

        QVariantMap rawData;

        QString sectionTitle;
        QString uid;
        QString feedSource;
        QString feedName;
        QString feedColor;
        QDateTime date;
        QString title;
        QString body;

        QString link;

        qint64 mediaDuration;
        QString thumbnail;
        QList<Enclosure> enclosures;

        bool isShelved;
        bool isRead;
    };

    enum
    {
        SectionTitleRole,
        UidRole,

        FeedSourceRole,
        FeedNameRole,
        FeedColorRole,

        DateRole,
        TitleRole,
        BodyRole,

        LinkRole,

        MediaDurationRole,
        ThumbnailRole,
        EnclosuresRole,

        IsShelvedRole,
        IsReadRole
    };

    enum SortMode
    {
        LatestFirst,
        OldestFirst,
        FeedLatestFirst,
        FeedOldestFirst
    };

    explicit NewsBlendModel(QObject* parent = 0);

    virtual QHash<int, QByteArray> roleNames() const { return myRolenames; }
    virtual int rowCount(const QModelIndex& parent) const;
    virtual QVariant data(const QModelIndex& index, int role) const;

    Q_INVOKABLE void setSectionTitle(const QString& title) { myCurrentSectionTitle = title; }

    Q_INVOKABLE QVariantMap getItem(int index) const;
    Q_INVOKABLE void loadItems(const QVariantList& jsons, bool shelved);
    Q_INVOKABLE int addItem(const QVariantMap& itemData, bool update = true);
    Q_INVOKABLE bool hasItem(const QString& feedSource,
                             const QString& uid) const;

    Q_INVOKABLE bool isRead(int index) const { return myItems.at(index)->isRead; }
    Q_INVOKABLE void setRead(int index, bool value);

    Q_INVOKABLE bool isShelved(int index) const { return myItems.at(index)->isShelved; }
    Q_INVOKABLE void setShelved(int index, bool value);

    Q_INVOKABLE void removeReadItems(const QString& feedSource = QString());
    Q_INVOKABLE void removeFeedItems(const QString& feedSource);

    Q_INVOKABLE int previousOfFeed(int index) const;
    Q_INVOKABLE int nextOfFeed(int index) const;
    Q_INVOKABLE int firstOfFeed(const QString& feedSource) const;

signals:
    void sortModeChanged();
    void shelvedChanged(int index);
    void readChanged(int index);
    void sectionTitleRequested(const QString& itemFeed,
                               const QDateTime& itemDate);

private:
    SortMode sortMode() const { return mySortMode; }
    void setSortMode(SortMode mode);

    QList<Enclosure> findEnclosures(const QVariantMap& itemData) const;
    QString findThumbnail(const QVariantMap& itemData) const;

    Item::Ptr parseItem(const QVariantMap& itemData) const;
    int insertItem(const Item::Ptr item, bool update = true);

private:
    QHash<int, QByteArray> myRolenames;

    QList<Item::Ptr> myItems;
    typedef QPair<QString, QString> FullId;
    QMap<FullId, Item::Ptr> myItemMap;

    SortMode mySortMode;

    QString myCurrentSectionTitle;
};

#endif // NEWSBLENDMODEL_H
