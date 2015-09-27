#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

class QSqlDatabase;

class Database : public QObject
{
    Q_OBJECT
public:
    explicit Database(QObject* parent = 0);

    Q_INVOKABLE void vacuum() const;

    // Returns the feed sources.
    Q_INVOKABLE QVariantList sources() const;
    // Adds a new feed source.
    Q_INVOKABLE int addSource(const QString& name,
                              const QString& url,
                              const QString& color);
    // Changes a feed source.
    Q_INVOKABLE void changeSource(int sourceId,
                                  const QString& name,
                                  const QString& url,
                                  const QString& color);
    // Removes a feed source.
    Q_INVOKABLE void removeSource(int sourceId);
    // Sets the positions of the feed sources.
    Q_INVOKABLE void setPositions(const QVariantList& sourceIds);

    // Loads a list of {url, uid, document, body} records into the offline cache.
    Q_INVOKABLE void cacheItems(const QVariantList& items);
    // Removes all read items from the offline cache.
    Q_INVOKABLE void uncacheReadItems();

    // Marks the items given as a list {url, uid, value} records as read or
    // unread, depending on their value property.
    Q_INVOKABLE void setItemsRead(const QVariantList& items);
    // Returns if the given item is marked as read.
    Q_INVOKABLE bool isRead(const QString& url, const QString& uid) const;
    // Forgets about read items older than the given amount of seconds.
    // This helps reduce disk space consumption.
    Q_INVOKABLE void forgetRead(int age);
    // Forgets about read items of the given feed source.
    Q_INVOKABLE void forgetSourceRead(const QString& url);

    // Returns the counts of shelved items per feed source.
    Q_INVOKABLE QVariantMap shelvedCounts() const;
    // Returns the counts of cached items per feed source.
    Q_INVOKABLE QVariantMap cachedCounts() const;

    // Loads the cached items in batches.
    Q_INVOKABLE QVariantList batchLoadCached(int offset, int batchSize) const;
    // Loads the shelved items in batches.
    Q_INVOKABLE QVariantList batchLoadShelved(int offset, int batchSize) const;

    // Shelves the given item.
    Q_INVOKABLE void shelveItem(const QString& url, const QString& uid);
    // Unshelves the given item.
    Q_INVOKABLE void unshelveItem(const QString& url, const QString& uid);
    // Returns if the given item is shelved.
    Q_INVOKABLE bool isShelved(const QString& url, const QString& uid) const;

    // Returns the serialized data of the given feed item.
    Q_INVOKABLE QString cachedItem(const QString& url, const QString& uid) const;
    // Returns the body data of the given feed item.
    Q_INVOKABLE QString itemBody(const QString& url, const QString& uid) const;

    // Sets an audio bookmark.
    Q_INVOKABLE void setAudioBookmark(const QString& url,
                                      int milliseconds);
    // Returns the audio bookmark position for the given URL, or 0 if there is
    // no bookmark set.
    Q_INVOKABLE int audioBookmark(const QString& url) const;

    // Sets a configuration key.
    Q_INVOKABLE void configSet(const QString& key, const QString& value);
    // Retrieves a configuration key.
    Q_INVOKABLE QString configGet(const QString& key, const QString& defaultValue) const;

private:
    QString locateDatabase() const;
    void migrate();
    void createSchema() const;

    void migrateRev2() const;
    void migrateRev3() const;
    void migrateRev4() const;
    void migrateRev5() const;
    void migrateRev6() const;
    void migrateRev7() const;
    void migrateRev8() const;
    void migrateRev9() const;
    void migrateRev10() const;
    void migrateRev11() const;


private:
    QSqlDatabase myDb;
};

#endif // DATABASE_H
