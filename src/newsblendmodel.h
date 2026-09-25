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
#include <QThread>

class Database;
class PersistedLoader;

class NewsBlendModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(SortMode)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode
               NOTIFY sortModeChanged)
    Q_PROPERTY(bool unreadOnly READ unreadOnly WRITE setUnreadOnly
               NOTIFY unreadOnlyChanged)
    Q_PROPERTY(QString selectedFeed READ selectedFeed WRITE setSelectedFeed
               NOTIFY selectedFeedChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
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
    virtual ~NewsBlendModel();

    virtual QHash<int, QByteArray> roleNames() const { return myRolenames; }
    virtual int rowCount(const QModelIndex& parent) const;
    virtual QVariant data(const QModelIndex& index, int role) const;

    Q_INVOKABLE QVariant getAttribute(int index, const QString& role) const;

    Q_INVOKABLE void loadItems(const QVariantList& jsons, bool shelved);
    /* Loads all persisted items (offline cache + shelf) from the given
     * database. The parsing happens on a background thread, the model
     * is updated (and sorted) only once on the main thread.
     */
    Q_INVOKABLE void loadPersisted(Database* db);
    /* Loads the items of the given QML feed model (an XmlListModel-based
     * model) into this model and into the offline cache of the given
     * database. Items that are already known, or that are read and not
     * shelved, are skipped.
     *
     * The feed model is declared as QObject* because the QML type checker
     * does not know the C++ type QAbstractItemModel; XmlListModel is a
     * QAbstractItemModel, so casting it on the C++ side is safe.
     */
    Q_INVOKABLE void loadFromFeedModel(QObject* feedModel,
                                       const QString& feedSource,
                                       const QString& logo,
                                       Database* db);
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
    void readyChanged();
    void sortModeChanged();
    void unreadOnlyChanged();
    void selectedFeedChanged();
    void countChanged();
    void shelvedChanged(int index);
    void readChanged(QVariantList items);

private slots:
    /* Called (on the main thread) when the persisted item loader finished.
     */
    void persistedLoaderFinished();

private:
    void reinsertItems();

    SortMode sortMode() const { return mySortMode; }
    void setSortMode(SortMode mode);

    bool unreadOnly() const { return myUnreadOnly; }
    void setUnreadOnly(bool newUnreadOnly);

    QString selectedFeed() const { return mySelectedFeed; }
    void setSelectedFeed(const QString& selectedFeed);

    int count() const { return rowCount(QModelIndex()); }
    int totalCount() const { return myItems.size(); }

    bool ready() const { return myReady; }

    /* Merges the given items into the item map without touching the view
     * list, so that sorting can be deferred until all items are loaded.
     */
    void mergeItems(const QVariantList& jsons, bool shelved);

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
    bool myUnreadOnly = {false};
    bool myReady = {false};

    // the background thread loading the persisted items (null if idle)
    PersistedLoader* myLoader = 0;
};

/* Loads and parses the persisted feed items on a background thread.
 * The documents must have been fetched from the database on the main
 * thread before starting (the worker must not touch the database).
 */
class PersistedLoader : public QThread
{
    Q_OBJECT
public:
    struct Result
    {
        QList<NewsBlendModel::Item::Ptr> items;
        QMap<QString, QString> logos;
    };

    explicit PersistedLoader(QObject* parent = 0);

    void setDocuments(const QList<QByteArray>& cached,
                      const QList<QByteArray>& shelved);

    /* Returns the parsed items. Only valid after run() has finished.
     */
    const Result& result() const { return myResult; }

protected:
    virtual void run();

private:
    void parseDocument(const QByteArray& document, bool shelved);

    QList<QByteArray> myCached;
    QList<QByteArray> myShelved;
    Result myResult;
};

#endif // NEWSBLENDMODEL_H
