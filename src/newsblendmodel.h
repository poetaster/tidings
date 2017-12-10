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
#include <QStringList>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QSharedPointer>

class NewsBlendModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(SortMode)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode
               NOTIFY sortModeChanged)
    Q_PROPERTY(QString selectedFeed READ selectedFeed WRITE setSelectedFeed
               NOTIFY selectedFeedChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)
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

        QString uid;
        QString feedSource;
        QDateTime date;
        QString title;

        QString link;

        qint64 mediaDuration;
        QString thumbnail;
        QList<Enclosure> enclosures;

        bool isShelved;
        bool isRead;
    };

    enum
    {
        UidRole,

        FeedSourceRole,

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
        FeedOldestFirst,
        FeedOnlyLatestFirst,
        FeedOnlyOldestFirst
    };

    explicit NewsBlendModel(QObject* parent = 0);

    virtual QHash<int, QByteArray> roleNames() const { return myRolenames; }
    virtual int rowCount(const QModelIndex& parent) const;
    virtual QVariant data(const QModelIndex& index, int role) const;

    Q_INVOKABLE QVariant getAttribute(int index, const QString& role) const;

    Q_INVOKABLE void loadItems(const QVariantList& jsons, bool shelved);
    Q_INVOKABLE int addItem(const QVariantMap& itemData, bool update = true);
    Q_INVOKABLE bool hasItem(const QString& feedSource,
                             const QString& uid) const;

    Q_INVOKABLE bool isRead(int index) const { return myItems.at(index)->isRead; }
    Q_INVOKABLE void setRead(int index, bool value);
    Q_INVOKABLE void setFeedRead(const QString& feedSource, bool value);
    Q_INVOKABLE void setVisibleRead();
    Q_INVOKABLE void setAllRead();

    Q_INVOKABLE bool isShelved(int index) const { return myItems.at(index)->isShelved; }
    Q_INVOKABLE void setShelved(int index, bool value);

    Q_INVOKABLE void removeReadItems(const QString& feedSource = QString());
    Q_INVOKABLE void removeFeedItems(const QString& feedSource);

    Q_INVOKABLE int previousOfFeed(int index) const;
    Q_INVOKABLE int nextOfFeed(int index) const;
    Q_INVOKABLE int firstOfFeed(const QString& feedSource) const;

    Q_INVOKABLE QString logoOfFeed(const QString& feedSource) const;
    Q_INVOKABLE QStringList thumbnailsOfFeed(const QString& feedSource) const;

    /* Returns the total count of items per feed source.
     */
    Q_INVOKABLE QVariantMap totalStats() const;

    /* Returns the count of unread items per feed source.
     */
    Q_INVOKABLE QVariantMap unreadStats() const;

signals:
    void sortModeChanged();
    void selectedFeedChanged();
    void countChanged();
    void shelvedChanged(int index);
    void readChanged(QVariantList items);

private:
    void reinsertItems();

    SortMode sortMode() const { return mySortMode; }
    void setSortMode(SortMode mode);

    QString selectedFeed() const { return mySelectedFeed; }
    void setSelectedFeed(const QString& selectedFeed);

    int count() const { return rowCount(QModelIndex()); }
    int totalCount() const { return myItems.size(); }

    QList<Enclosure> findEnclosures(const QVariantMap& itemData) const;
    QString findThumbnail(const QVariantMap& itemData) const;
    QString findLink(const QVariantMap& itemData) const;

    Item::Ptr parseItem(const QVariantMap& itemData) const;
    int insertItem(const Item::Ptr item, bool update = true);

private:
    QHash<int, QByteArray> myRolenames;
    QHash<QByteArray, int> myInverseRolenames;

    QList<Item::Ptr> myItems;
    typedef QPair<QString, QString> FullId;
    QMap<FullId, Item::Ptr> myItemMap;

    QMap<QString, int> myTotalCounts;
    QMap<QString, int> myUnreadCounts;
    QMap<QString, QString> myFeedLogos;

    SortMode mySortMode;
    QString mySelectedFeed;
};

#endif // NEWSBLENDMODEL_H
