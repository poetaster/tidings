#include "database.h"

#include <QDateTime>
#include <QDir>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

#include <QDebug>

namespace
{
/* Revision of the database. Every schema modification increases the revision.
 * Implement a migration function to that revision from the previous one and
 * call it in migrate.
 * Update createSchema with the schema modifications.
 */
const int REVISION = 11;

/* Name of the database file, if not created by QML earlier.
 */
const QString DATABASE("database.sqlite");
}

Database::Database(QObject* parent)
    : QObject(parent)
{
    myDb = QSqlDatabase::addDatabase("QSQLITE");

    const QString db = locateDatabase();
    if (! db.isEmpty())
    {
        qDebug() << "Found database" << db;
        myDb.setDatabaseName(db);
        myDb.open();
    }
    else
    {
        qDebug() << "Failed to locate database";
    }

    if (myDb.open())
    {
        migrate();
    }
}

QString Database::locateDatabase() const
{
    const QStringList dataPaths = QStandardPaths::standardLocations(
                QStandardPaths::DataLocation);


    foreach (const QString& path, dataPaths)
    {
        qDebug() << "Looking for database in" << path;

        const QString defaultDatabase(QDir(path).absoluteFilePath(DATABASE));
        if (QFile(defaultDatabase).exists())
        {
            return defaultDatabase;
        }

        const QString legacyPath =
                QDir(path).absoluteFilePath("QML/OfflineStorage/Databases");
        const QDir legacyDir(legacyPath);
        if (legacyDir.exists())
        {
            foreach (const QString& fileName, legacyDir.entryList())
            {
                if (fileName.endsWith(".sqlite"))
                {
                    // this is the file
                    return legacyDir.absoluteFilePath(fileName);
                }
            }
        }
    }

    if (! dataPaths.empty())
    {
        // create path if necessary
        if (! QDir(dataPaths.at(0)).mkpath("."))
        {
            qDebug() << "Failed to create database path" << dataPaths.at(0);
            return QString();
        }
        return QDir(dataPaths.at(0)).absoluteFilePath(DATABASE);
    }
    else
    {
        return QString();
    }
}

void Database::migrate()
{
    myDb.exec("CREATE TABLE IF NOT EXISTS status ("
              "  keyname TEXT,"
              "  value TEXT"
              ")");
    QSqlQuery query;
    query.prepare("SELECT value FROM status WHERE keyname = ?");
    query.addBindValue("revision");
    query.exec();

    int revision = 0;
    if (query.next())
    {
        revision = query.value(0).toInt();
    }
    qDebug() << "Found database revision" << revision;

    myDb.transaction();
    if (revision == 0)
    {
        // nothing to migrate as this is a new database, so we just jump to the
        // current revision
        qDebug() << "This is a new database";
        createSchema();
    }
    else
    {
        if (revision < 2) migrateRev2();
        if (revision < 3) migrateRev3();
        if (revision < 4) migrateRev4();
        if (revision < 5) migrateRev5();
        if (revision < 6) migrateRev6();
        if (revision < 7) migrateRev7();
        if (revision < 8) migrateRev8();
        if (revision < 9) migrateRev9();
        if (revision < 10) migrateRev10();
        if (revision < 11) migrateRev11();
    }

    // set the new revision
    if (revision == 0)
    {
        query = QSqlQuery();
        query.prepare("INSERT INTO status (keyname, value) VALUES (?, ?)");
        query.addBindValue("revision");
        query.addBindValue(REVISION);
        query.exec();
    }
    else if (revision != REVISION)
    {
        qDebug() << "Updating database revision to" << REVISION;
        query = QSqlQuery();
        query.prepare("UPDATE status SET value = ? WHERE keyname = ?");
        query.addBindValue(REVISION);
        query.addBindValue("revision");
        query.exec();
    }
    myDb.commit();
}

/* Migrates to Rev 2, where we added color tags.
 */
void Database::migrateRev2() const
{
    myDb.exec("ALTER TABLE sources ADD COLUMN color VARCHAR(9) DEFAULT '#00c0a0'");
}

/* Migrates to Rev 3, where we added a table for read items.
 */
void Database::migrateRev3() const
{
    myDb.exec("CREATE TABLE read ("
              "  url TEXT,"
              "  uid TEXT"
              ")");
}

/* Migrates to Rev 4, where read items got a timestamp.
 */
void Database::migrateRev4() const
{
    myDb.exec("ALTER TABLE read ADD COLUMN read INT DEFAULT 0");
}

/* Migrates to Rev 5, where we added a shelf for kept items.
 */
void Database::migrateRev5() const
{
    myDb.exec("CREATE TABLE shelf ("
              "  url TEXT,"
              "  uid TEXT,"
              "  document TEXT"
              ")");
}

/* Migrates to Rev 6, where we added a table for configuration.
 */
void Database::migrateRev6() const
{
    myDb.exec("CREATE TABLE config ("
              "  key VARCHAR(256),"
              "  value TEXT"
              ")");
}

/* Migrates to Rev 7, where we added a table for caching unread items.
 */
void Database::migrateRev7() const
{
    myDb.exec("CREATE TABLE unread ("
              "  url TEXT,"
              "  uid TEXT,"
              "  document TEXT"
              ")");
}

/* Migrates to Rev 8, where we renamed table 'unread' to 'offlineCache'.
 */
void Database::migrateRev8() const
{
    myDb.exec("ALTER TABLE unread RENAME TO offlineCache");
}

/* Migrates to Rev 9, where we added audio bookmarks.
 */
void Database::migrateRev9() const
{
    myDb.exec("CREATE TABLE audioBookmarks ("
              "  url TEXT,"
              "  position INT"
              ")");
}

/* Migrates to Rev 10, where we added a table for the item bodies.
 */
void Database::migrateRev10() const
{
    myDb.exec("CREATE TABLE bodies ("
              "  url TEXT,"
              "  uid TEXT,"
              "  body TEXT"
              ")");
}

/* Migrates to Rev 11, where we added a sorting position to the feed sources.
 */
void Database::migrateRev11() const
{
    myDb.exec("ALTER TABLE sources ADD COLUMN position INT DEFAULT 0");
}

/* Creates the initial schema.
 */
void Database::createSchema() const
{
    myDb.exec("CREATE TABLE sources ("
              "  sourceid INT,"
              "  name TEXT,"
              "  url TEXT,"
              "  color VARCHAR(9),"
              "  position INT"
              ")");

    myDb.exec("CREATE TABLE read ("
              "  url TEXT,"
              "  uid TEXT,"
              "  read INT"
              ")");

    myDb.exec("CREATE TABLE shelf ("
              "  url TEXT,"
              "  uid TEXT,"
              "  document TEXT"
              ")");

    myDb.exec("CREATE TABLE offlineCache ("
              "  url TEXT,"
              "  uid TEXT,"
              "  document TEXT"
              ")");

    myDb.exec("CREATE TABLE bodies ("
              "  url TEXT,"
              "  uid TEXT,"
              "  body TEXT"
              ")");

    myDb.exec("CREATE TABLE config ("
              "  key VARCHAR(256),"
              "  value TEXT"
              ")");

    myDb.exec("CREATE TABLE audioBookmarks ("
              "  url TEXT,"
              "  position INT"
              ")");
}

void Database::vacuum() const
{
    if (myDb.isOpen())
    {
        qDebug() << "Vacuuming database... *vrooom*";
        QSqlQuery query = myDb.exec("VACUUM");
        if (query.lastError().type() != QSqlError::NoError)
        {
            qDebug() << query.lastQuery() << query.lastError();
        }
        else
        {
            qDebug() << "Done.";
        }
    }
}

QVariantList Database::sources() const
{
    QVariantList result;

    QSqlQuery query;
    query.prepare("SELECT sourceid, name, url, color "
                  "FROM sources "
                  "ORDER BY position");
    query.exec();

    while (query.next())
    {
        QVariantMap item;
        item.insert("sourceId", query.value(0));
        item.insert("name", query.value(1));
        item.insert("url", query.value(2));
        item.insert("color", query.value(3));
        result << item;
    }

    return result;
}

int Database::addSource(const QString& name,
                         const QString& url,
                         const QString& color)
{
    int nextId = 0;
    int position = 0;

    myDb.transaction();

    QSqlQuery query;
    query.prepare("SELECT max(sourceid), count(*) "
                  "FROM sources");
    query.exec();
    if (query.next())
    {
        nextId = query.value(0).toInt() + 1;
        position = query.value(1).toInt();
    }
    query = QSqlQuery();
    query.prepare("INSERT INTO sources (sourceid, name, url, color, position) "
                  "VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(nextId);
    query.addBindValue(name);
    query.addBindValue(url);
    query.addBindValue(color);
    query.addBindValue(position);
    query.exec();

    myDb.commit();

    return nextId;
}

void Database::changeSource(int sourceId,
                            const QString& name,
                            const QString& url,
                            const QString& color)
{
    QSqlQuery query;
    query.prepare("UPDATE sources "
                  "SET name = ?, url = ?, color = ? "
                  "WHERE sourceid = ?");
    query.addBindValue(name);
    query.addBindValue(url);
    query.addBindValue(color);
    query.addBindValue(sourceId);
    query.exec();
}

void Database::removeSource(int sourceId)
{
    myDb.transaction();

    QSqlQuery query;
    query.prepare("SELECT url FROM sources WHERE sourceid = ?");
    query.addBindValue(sourceId);
    query.exec();
    if (query.next())
    {
        const QString url = query.value(0).toString();
        QSqlQuery q;
        q.prepare("DELETE FROM offlineCache WHERE url = ?");
        q.addBindValue(url);
        q.exec();
        q = QSqlQuery();
        q.prepare("DELETE FROM read WHERE url = ?");
        q.addBindValue(url);
        q.exec();
        q = QSqlQuery();
        q.prepare("DELETE FROM shelf WHERE url = ?");
        q.addBindValue(url);
        q.exec();
        q = QSqlQuery();
        q.prepare("DELETE FROM bodies WHERE url = ?");
        q.addBindValue(url);
        q.exec();
    }
    query = QSqlQuery();
    query.prepare("DELETE FROM sources WHERE sourceid = ?");
    query.addBindValue(sourceId);
    query.exec();

    myDb.commit();
}

void Database::setPositions(const QVariantList& sourceIds)
{
    myDb.transaction();
    int position = 0;
    foreach (const QVariant& sourceId, sourceIds)
    {
        QSqlQuery query;
        query.prepare("UPDATE sources "
                      "SET position = ? "
                      "WHERE sourceid = ?");
        query.addBindValue(position);
        query.addBindValue(sourceId);
        query.exec();
        ++position;
    }
    myDb.commit();
}

void Database::cacheItems(const QVariantList& items)
{
    myDb.transaction();
    foreach (const QVariant& item, items)
    {
        QVariantMap map = item.toMap();
        QSqlQuery query;
        query.prepare("INSERT INTO offlineCache (url, uid, document) "
                      "VALUES (?, ?, ?)");
        query.addBindValue(map.value("url"));
        query.addBindValue(map.value("uid"));
        query.addBindValue(map.value("document"));
        query.exec();

        query = QSqlQuery();
        query.prepare("INSERT INTO bodies (url, uid, body) "
                      "VALUES (?, ?, ?)");
        query.addBindValue(map.value("url"));
        query.addBindValue(map.value("uid"));
        query.addBindValue(map.value("body"));
        query.exec();
    }

    myDb.commit();
}

void Database::uncacheReadItems()
{
    myDb.transaction();
    QSqlQuery query;
    // shelved items are not in the offline cache
    query.exec("DELETE FROM offlineCache "
               "WHERE url || uid IN (SELECT url || uid FROM read)");
    // don't delete from bodies what is shelved
    query.exec("DELETE FROM bodies "
               "WHERE url || uid IN (SELECT url || uid FROM read) AND "
               "      url || uid NOT IN (SELECT url || uid FROM shelf)");

    myDb.commit();
}

void Database::setItemsRead(const QVariantList& items)
{
    myDb.transaction();

    int now = QDateTime::currentMSecsSinceEpoch() / 1000;

    foreach (const QVariant& item, items)
    {
        QVariantMap map = item.toMap();
        bool value = map.value("value").toBool();
        QSqlQuery query;
        if (value)
        {
            query.prepare("INSERT INTO read (url, uid, read) "
                          "VALUES (?, ?, ?)");
            query.addBindValue(map.value("url"));
            query.addBindValue(map.value("uid"));
            query.addBindValue(now);
        }
        else
        {
            query.prepare("DELETE FROM read WHERE url = ? AND uid = ?");
            query.addBindValue(map.value("url"));
            query.addBindValue(map.value("uid"));
        }
        query.exec();
    }

    myDb.commit();
}

bool Database::isRead(const QString& url, const QString& uid) const
{
    QSqlQuery query;
    query.prepare("SELECT url FROM read "
                  "WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();
    return query.next();
}

void Database::forgetRead(int age)
{
    int now = QDateTime::currentMSecsSinceEpoch() / 1000;
    int then = now - age;
    QSqlQuery query;
    query.prepare("DELETE FROM read WHERE read < ?");
    query.addBindValue(then);
    query.exec();
}

void Database::forgetSourceRead(const QString& url)
{
    QSqlQuery query;
    query.prepare("DELETE FROM read WHERE url = ?");
    query.addBindValue(url);
    query.exec();
}

QVariantMap Database::shelvedCounts() const
{
    QVariantMap result;

    QSqlQuery query;
    query.exec("SELECT url, cound(DISTINCT uid) "
               "FROM shelf "
               "GROUP BY url");
    while (query.next())
    {
        result.insert(query.value(0).toString(),
                      query.value(1));
    }

    return result;
}

QVariantMap Database::cachedCounts() const
{
    QVariantMap result;

    QSqlQuery query;
    query.exec("SELECT url, cound(DISTINCT uid) "
               "FROM offlineCache "
               "GROUP BY url");
    while (query.next())
    {
        result.insert(query.value(0).toString(),
                      query.value(1));
    }

    return result;
}

QVariantList Database::batchLoadCached(int offset, int batchSize) const
{
    QVariantList result;

    QSqlQuery q = myDb.exec(QString("SELECT document FROM offlineCache "
                                    "ORDER BY uid LIMIT %1 OFFSET %2")
                            .arg(batchSize)
                            .arg(offset));
    while (q.next())
    {
        result << q.value(0).toString();
    }

    return result;
}

QVariantList Database::batchLoadShelved(int offset, int batchSize) const
{
    QVariantList result;

    QSqlQuery q = myDb.exec(QString("SELECT document FROM shelf "
                                    "ORDER BY uid LIMIT %1 OFFSET %2")
                            .arg(batchSize)
                            .arg(offset));
    while (q.next())
    {
        result << q.value(0).toString();
    }

    return result;
}

void Database::shelveItem(const QString& url, const QString& uid)
{
    myDb.transaction();

    QSqlQuery query;
    query.prepare("INSERT INTO shelf (url, uid, document) "
                  "SELECT url, uid, document "
                  "FROM offlineCache "
                  "WHERE url = ? AND uid  = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    query = QSqlQuery();
    query.prepare("DELETE FROM offlineCache WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    myDb.commit();
}

void Database::unshelveItem(const QString& url, const QString& uid)
{
    myDb.transaction();

    QSqlQuery query;
    query.prepare("INSERT INTO offlineCache (url, uid, document) "
                  "SELECT url, uid, document "
                  "FROM shelf "
                  "WHERE url = ? AND uid  = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    query = QSqlQuery();
    query.prepare("DELETE FROM shelf WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    myDb.commit();
}

bool Database::isShelved(const QString& url, const QString& uid) const
{
    QSqlQuery query;
    query.prepare("SELECT url "
                  "FROM shelf "
                  "WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    return query.next();
}

QString Database::cachedItem(const QString& url, const QString& uid) const
{
    // the item is either in the offline cache (more likely) or on the shelf
    QSqlQuery query;
    query.prepare("SELECT document "
                  "FROM offlineCache "
                  "WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    if (query.next())
    {
        return query.value(0).toString();
    }

    query = QSqlQuery();
    query.prepare("SELECT document "
                  "FROM shelf "
                  "WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    if (query.next())
    {
        return query.value(0).toString();
    }
    else
    {
        return QString();
    }
}

QString Database::itemBody(const QString& url, const QString& uid) const
{
    QSqlQuery query;
    query.prepare("SELECT body "
                  "FROM bodies "
                  "WHERE url = ? AND uid = ?");
    query.addBindValue(url);
    query.addBindValue(uid);
    query.exec();

    if (query.next())
    {
        return query.value(0).toString();
    }
    else
    {
        return QString();
    }
}

void Database::setAudioBookmark(const QString& url, int milliseconds)
{
    myDb.transaction();

    QSqlQuery query;
    query.prepare("SELECT url "
                  "FROM audioBookmarks "
                  "WHERE url = ?");
    query.addBindValue(url);
    query.exec();

    if (query.next())
    {
        QSqlQuery q;
        q.prepare("UPDATE audioBookmarks "
                  "SET position = ? "
                  "WHERE url = ?");
        q.addBindValue(milliseconds);
        q.addBindValue(url);
        q.exec();
    }
    else
    {
        QSqlQuery q;
        q.prepare("INSERT INTO audioBookmarks (url, position) "
                  "VALUES (?, ?)");
        q.addBindValue(url);
        q.addBindValue(milliseconds);
        q.exec();
    }

    myDb.commit();
}

int Database::audioBookmark(const QString& url) const
{
    QSqlQuery query;
    query.prepare("SELECT position "
                  "FROM audioBookmarks "
                  "WHERE url = ?");
    query.addBindValue(url);
    query.exec();
    if (query.next())
    {
        return query.value(0).toInt();
    }
    else
    {
        return 0;
    }
}

void Database::configSet(const QString& key, const QString& value)
{
    myDb.transaction();

    QSqlQuery query;
    query.prepare("SELECT key FROM config WHERE key = ?");
    query.addBindValue(key);
    query.exec();
    if (query.next())
    {
        QSqlQuery q;
        q.prepare("UPDATE config SET value = ? WHERE key = ?");
        q.addBindValue(value);
        q.addBindValue(key);
        q.exec();
    }
    else
    {
        QSqlQuery q;
        q.prepare("INSERT INTO config (key, value) VALUES (?, ?)");
        q.addBindValue(key);
        q.addBindValue(value);
        q.exec();
    }

    myDb.commit();
}

QString Database::configGet(const QString& key, const QString& defaultValue) const
{
    QSqlQuery query;
    query.prepare("SELECT value FROM config WHERE key = ?");
    query.addBindValue(key);
    query.exec();
    if (query.next())
    {
        return query.value(0).toString();
    }
    else
    {
        return defaultValue;
    }
}
