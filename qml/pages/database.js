.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

/* Revision of the database. Every schema modification increases the revision.
 * Implement a migration function to that revision from the previous one and
 * call it in _migrate.
 * Update _createSchema with the schema modifications.
 */
var _REVISION = 9;

var _database = Sql.LocalStorage.openDatabaseSync("TidingsDB", "1.0",
                                                  "Tidings Persisted Settings");

_database.transaction(_migrate);

/* Migrates the database to the current schema revision. This must be the first
 * action after opening the database.
 */
function _migrate(tx) {
    // retrieve revision
    tx.executeSql("CREATE TABLE IF NOT EXISTS status (" +
                  "  keyname TEXT," +
                  "  value TEXT" +
                  ")");
    var res = tx.executeSql("SELECT value FROM status WHERE keyname = ?",
                            ["revision"]);
    var revision = 0;
    if (res.rows.length >= 1) {
        revision = res.rows.item(0).value;
    }

    console.log("Found database revision " + revision);

    if (revision === 0) {
        // nothing to migrate as this is a new database, so we just jump to the
        // current revision
        console.log("This is a new database");
        _createSchema(tx);
    } else {
        // perform schema migration
        if (revision < 2) { _migrateRev2(tx); }
        if (revision < 3) { _migrateRev3(tx); }
        if (revision < 4) { _migrateRev4(tx); }
        if (revision < 5) { _migrateRev5(tx); }
        if (revision < 6) { _migrateRev6(tx); }
        if (revision < 7) { _migrateRev7(tx); }
        if (revision < 8) { _migrateRev8(tx); }
        if (revision < 9) { _migrateRev9(tx); }
    }

    // set the new revision
    if (revision === 0) {
        tx.executeSql("INSERT INTO status (keyname, value) VALUES (?, ?)",
                      ["revision", _REVISION]);
    } else if (revision < _REVISION) {
        console.log("Updating database revision to " + _REVISION);
        tx.executeSql("UPDATE status SET value = ? WHERE keyname = ?",
                      [_REVISION, "revision"]);
    }
}

/* Migrates to Rev 2, where we added color tags.
 */
function _migrateRev2(tx)
{
    tx.executeSql("ALTER TABLE sources ADD COLUMN color VARCHAR(9) DEFAULT '#00c0a0'");
}

/* Migrates to Rev 3, where we added a table for read items.
 */
function _migrateRev3(tx)
{
    tx.executeSql("CREATE TABLE read (" +
                  "  url TEXT," +
                  "  uid TEXT" +
                  ")");
}

/* Migrates to Rev 4, where read items got a timestamp.
 */
function _migrateRev4(tx)
{
    tx.executeSql("ALTER TABLE read ADD COLUMN read INT DEFAULT 0");
}

/* Migrates to Rev 5, where we added a shelf for kept items.
 */
function _migrateRev5(tx)
{
    tx.executeSql("CREATE TABLE shelf (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  document TEXT" +
                  ")");
}

/* Migrates to Rev 6, where we added a table for configuration.
 */
function _migrateRev6(tx)
{
    tx.executeSql("CREATE TABLE config (" +
                  "  key VARCHAR(256)," +
                  "  value TEXT" +
                  ")");
}

/* Migrates to Rev 7, where we added a table for caching unread items.
 */
function _migrateRev7(tx)
{
    tx.executeSql("CREATE TABLE unread (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  document TEXT" +
                  ")");
}

/* Migrates to Rev 8, where we renamed table 'unread' to 'offlineCache'.
 */
function _migrateRev8(tx)
{
    tx.executeSql("ALTER TABLE unread RENAME TO offlineCache");
}

/* Migrates to Rev 9, where we added audio bookmarks.
 */
function _migrateRev9(tx)
{
    tx.executeSql("CREATE TABLE audioBookmarks (" +
                  "  url TEXT," +
                  "  position INT" +
                  ")");
}

/* Creates the initial schema.
 */
function _createSchema(tx)
{
    tx.executeSql("CREATE TABLE sources (" +
                  "  sourceid INT," +
                  "  name TEXT," +
                  "  url TEXT," +
                  "  color VARCHAR(9)" +
                  ")");

    tx.executeSql("CREATE TABLE read (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  read INT" +
                  ")");

    tx.executeSql("CREATE TABLE shelf (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  document TEXT" +
                  ")");

    tx.executeSql("CREATE TABLE offlineCache (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  document TEXT" +
                  ")");

    tx.executeSql("CREATE TABLE config (" +
                  "  key VARCHAR(256)," +
                  "  value TEXT" +
                  ")");

    tx.executeSql("CREATE TABLE audioBookmarks (" +
                  "  url TEXT," +
                  "  position INT" +
                  ")");
}

/* Returns the feed sources.
 */
function sources() {

    var result = [];

    function f(tx) {
        var res = tx.executeSql("SELECT sourceid, name, url, color "
                                + "FROM sources");
        for (var i = 0; i < res.rows.length; i++)
        {
            var item = res.rows.item(i);
            result.push({
                            "sourceId": item.sourceid,
                            "name": item.name,
                            "url": item.url,
                            "color": item.color
                        });
        }
    }

    _database.transaction(f);
    return result;
}

/* Adds a new feed source.
 */
function addSource(name, url, color) {

    var nextId = 0;

    function f(tx) {
        var res = tx.executeSql("SELECT max(sourceid) as sourceid FROM sources");
        if (res.rows.length) {
            nextId = res.rows.item(0).sourceid + 1;
        } else {
            nextId = 0;
        }
        tx.executeSql("INSERT INTO sources (sourceid, name, url, color) "
                      + "VALUES (?, ?, ?, ?)",
                      [nextId, name, url, color]);
    }

    _database.transaction(f);
    return nextId;
}

/* Changes a feed source.
 */
function changeSource(sourceId, name, url, color) {

    function f(tx) {
        tx.executeSql("UPDATE sources SET name = ?, url = ?, color = ? "
                      + "WHERE sourceid = ?",
                      [name, url, color, sourceId]);
    }

    _database.transaction(f);
}

/* Removes a feed source.
 */
function removeSource(sourceId) {

    function f(tx) {
        var res = tx.executeSql("SELECT url FROM sources WHERE sourceid = ?",
                                [sourceId]);

        if (res.rows.length) {
            var url = res.rows.item(0).url;
            tx.executeSql("DELETE FROM offlineCache WHERE url = ?",
                          [url]);
            tx.executeSql("DELETE FROM read WHERE url = ?",
                          [url]);
            tx.executeSql("DELETE FROM shelf WHERE url = ?",
                          [url]);
        }

        tx.executeSql("DELETE FROM sources WHERE sourceid = ?",
                      [sourceId]);
    }

   _database.transaction(f);
}

/* Loads a list of {url, uid, document} records into the offline cache.
 */
function cacheItems(items)
{
    function f(tx)
    {
        console.log("caching " + items.length + " items");
        for (var i = 0; i < items.length; ++i)
        {
            tx.executeSql("INSERT INTO offlineCache (url, uid, document) " +
                          "VALUES (?, ?, ?)",
                          [items[i].url, items[i].uid, items[i].document]);
        }
    }

    _database.transaction(f);
}

/* Removes the read items from the offline cache.
 */
function uncacheReadItems()
{
    function f(tx)
    {
        tx.executeSql("DELETE FROM offlineCache " +
                      "WHERE url || uid IN (SELECT url || uid FROM read)");
    }

    _database.transaction(f);
}

/* Marks the items given as a list {url, uid, value} records as read or unread,
 * depending on their value property.
 */
function setItemsRead(items)
{
    function f(tx)
    {
        var d = new Date();
        var now = d.getTime() / 1000;

        for (var i = 0; i < items.length; ++i)
        {
            var value = items[i].value;
            if (value)
            {
                tx.executeSql("INSERT INTO read (url, uid, read) VALUES (?, ?, ?)",
                              [items[i].url, items[i].uid, now]);
            }
            else
            {
                tx.executeSql("DELETE FROM read WHERE url = ? AND uid = ?",
                              [items[i].url, items[i].uid]);
            }
        }
    }

    _database.transaction(f);
}

/* Returns if the given item is marked as read.
 */
function isRead(url, uid) {
    var result = false;

    function f(tx) {
        var res = tx.executeSql("SELECT url FROM read WHERE url = ? AND uid = ?",
                                [url, uid]);
        result = (res.rows.length > 0);
    }

    _database.transaction(f);
    return result;
}

/* Forgets about read items older than the given amount of seconds.
 * This helps reduce disk space consumption.
 */
function forgetRead(age)
{

    function f(tx) {
        var d = new Date();
        var now = d.getTime() / 1000;
        var then = now - age;
        tx.executeSql("DELETE FROM read WHERE read < ?",
                      [then]);
    }

    _database.transaction(f);
}

/* Forgets about read items of the given feed source.
 */
function forgetSourceRead(sourceId)
{
    function f(tx) {
        tx.executeSql("DELETE FROM read WHERE url = ?",
                      [sourceId]);
    }

    _database.transaction(f);
}

/* Returns the counts of shelved items per feed source.
 */
function shelvedCounts()
{
    var result = {};

    function f(tx)
    {
        var res = tx.executeSql("SELECT url, count(DISTINCT uid) AS count " +
                                "FROM shelf " +
                                "GROUP BY url");
        for (var i = 0; i < res.rows.length; i++)
        {
            var data = res.rows.item(i);
            result[data.url] = data.count;
        }
    }

    _database.transaction(f);
    return result;
}

/* Returns the counts of cached items per feed source.
 */
function cachedCounts()
{
    var result = {};

    function f(tx)
    {
        var res = tx.executeSql("SELECT url, count(DISTINCT uid) AS count " +
                                "FROM offlineCache " +
                                "GROUP BY url");
        for (var i = 0; i < res.rows.length; i++)
        {
            var data = res.rows.item(i);
            result[data.url] = data.count;
        }
    }

    _database.transaction(f);
    return result;
}

/* Loads the cached items in batches via a callback.
 */
function batchLoadCached(batchSize, callback)
{
    function f(tx)
    {
        for (var offset = 0; true; offset += batchSize)
        {
            var res = tx.executeSql("SELECT document FROM offlineCache " +
                                    "ORDER BY uid LIMIT " + batchSize +
                                    " OFFSET " + offset);
            console.log("offset " + offset + " count " + res.rows.length);
            if (res.rows.length > 0)
            {
                callback(res.rows);
            }
            else
            {
                break;
            }
        }
    }

    _database.transaction(f);
}

/* Loads the shelved items in batches via a callback.
 */
function batchLoadShelved(batchSize, callback)
{
    function f(tx)
    {
        for (var offset = 0; true; offset += batchSize)
        {
            var res = tx.executeSql("SELECT document FROM shelf " +
                                    "ORDER BY uid LIMIT " + batchSize +
                                    " OFFSET " + offset);
            console.log("offset " + offset + " count " + res.rows.length);
            if (res.rows.length > 0)
            {
                callback(res.rows);
            }
            else
            {
                break;
            }
        }
    }

    _database.transaction(f);
}

/* Shelves the given item.
 */
function shelveItem(url, uid)
{
    function f(tx)
    {
        tx.executeSql("INSERT INTO shelf (url, uid, document) " +
                      "SELECT url, uid, document FROM offlineCache " +
                      "WHERE url = ? AND uid = ?",
                      [url, uid]);
        tx.executeSql("DELETE FROM offlineCache WHERE url = ? AND uid = ?",
                      [url, uid]);
    }

    _database.transaction(f);
}

/* Unshelves the given item.
 */
function unshelveItem(url, uid)
{
    function f(tx)
    {
        tx.executeSql("INSERT INTO offlineCache (url, uid, document) " +
                      "SELECT url, uid, document FROM shelf " +
                      "WHERE url = ? AND uid = ?",
                      [url, uid]);
        tx.executeSql("DELETE FROM shelf WHERE url = ? AND uid = ?",
                      [url, uid]);
    }

    _database.transaction(f);
}

/* Returns if the given item is shelved.
 */
function isShelved(url, uid)
{
    var result = false;

    function f(tx)
    {
        var res = tx.executeSql("SELECT url FROM shelf WHERE url = ? AND uid = ?",
                                [url, uid]);
        result = (res.rows.length > 0);
    }

    _database.transaction(f);
    return result;
}

/* Returns the serialized data of the given feed item.
 */
function cachedItem(url, uid)
{
    var result = "";

    function f(tx)
    {
        // the item is either in the offline cache (more likely) or on the shelf
        var res = tx.executeSql("SELECT document FROM offlineCache " +
                                "WHERE url = ? AND uid = ?",
                                [url, uid]);

        if (res.rows.length)
        {
            result = res.rows.item(0).document;
        }
        else
        {
            res = tx.executeSql("SELECT document FROM shelf " +
                                "WHERE url = ? AND uid = ?",
                                [url, uid]);
            if (res.rows.length)
            {
                result = res.rows.item(0).document;
            }
            else
            {
                console.log("not found");
            }
        }
    }

    _database.transaction(f);
    return result;
}

/* Sets an audio bookmark.
 */
function setAudioBookmark(url, millisecs)
{
    function f(tx)
    {
        var res = tx.executeSql("SELECT url FROM audioBookmarks WHERE url = ?",
                                [url]);
        if (res.rows.length > 0)
        {
            tx.executeSql("UPDATE audioBookmarks SET position = ? WHERE url = ?",
                          [millisecs, url]);
        }
        else
        {
            tx.executeSql("INSERT INTO audioBookmarks (url, position) " +
                          "VALUES (?, ?)",
                          [url, millisecs]);
        }
    }

    _database.transaction(f);
}

/* Returns the audio bookmark position for the given URL, or 0 if there is
 * no bookmark set.
 */
function audioBookmark(url)
{
    var result = 0;

    function f(tx)
    {
        var res = tx.executeSql("SELECT position FROM audioBookmarks " +
                                "WHERE url = ?",
                                [url]);
        if (res.rows.length > 0)
        {
            result = res.rows.item(0).position;
        }
    }

    _database.transaction(f);
    return result;
}

/* Sets a configuration key.
 */
function configSet(key, value)
{
    function f(tx)
    {
        var res = tx.executeSql("SELECT key FROM config WHERE key = ?",
                                [key]);
        if (res.rows.length > 0)
        {
            tx.executeSql("UPDATE config SET value = ? WHERE key = ?",
                          [value, key]);
        }
        else
        {
            tx.executeSql("INSERT INTO config (key, value) VALUES (?, ?)",
                          [key, value]);
        }
    }

    _database.transaction(f);
}

/* Retrieves a configuration key.
 */
function configGet(key, deflt)
{
    var result = deflt;

    function f(tx)
    {
        var res = tx.executeSql("SELECT value FROM config WHERE key = ?",
                                [key]);
        if (res.rows.length > 0)
        {
            result = res.rows.item(0).value;
        }
    }

    _database.transaction(f);
    return result;
}
