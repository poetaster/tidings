.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

/* Revision of the database. Every schema modification increases the revision.
 * Implement a migration function to that revision from the previous one and
 * call it in _migrate.
 * Update _createSchema with the schema modifications.
 */
var _REVISION = 7;

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
        if (revision < 1) { _migrateRev1(tx); }
        if (revision < 2) { _migrateRev2(tx); }
        if (revision < 3) { _migrateRev3(tx); }
        if (revision < 4) { _migrateRev4(tx); }
        if (revision < 5) { _migrateRev5(tx); }
        if (revision < 6) { _migrateRev6(tx); }
        if (revision < 7) { _migrateRev7(tx); }
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

/* Migrates to Rev 1.
 */
function _migrateRev1(tx)
{
    tx.executeSql("ALTER TABLE sources ADD COLUMN sourceid INT DEFAULT 0");
    var res = tx.executeSql("SELECT url FROM sources");
    var nextId = 0;
    for (var i = 0; i < res.rows.length; i++) {
        var url = res.rows.item(i).url;
        tx.executeSql("UPDATE sources SET sourceid = ? WHERE url = ?",
                      [nextId, url]);
        nextId++;
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

    tx.executeSql("CREATE TABLE unread (" +
                  "  url TEXT," +
                  "  uid TEXT," +
                  "  document TEXT" +
                  ")");

    tx.executeSql("CREATE TABLE config (" +
                  "  key VARCHAR(256)," +
                  "  value TEXT" +
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
            tx.executeSql("DELETE FROM read WHERE url = ?",
                          [res.rows.item(0).url]);
        }

        tx.executeSql("DELETE FROM sources WHERE sourceid = ?",
                      [sourceId]);
    }

   _database.transaction(f);
}

/* Marks the given item as read.
 */
function setRead(url, uid, value)
{
    function f(tx) {
        if (value) {
            var d = new Date();
            var now = d.getTime() / 1000;
            tx.executeSql("INSERT INTO read (url, uid, read) VALUES (?, ?, ?)",
                          [url, uid, now]);
            tx.executeSql("DELETE FROM unread WHERE url = ? AND uid = ?",
                          [url, uid]);
        } else {
            tx.executeSql("DELETE FROM read WHERE url = ? AND uid = ?",
                          [url, uid]);
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

/* Returns the counts of cached unread items per feed source.
 */
function cachedCounts()
{
    var result = {};

    function f(tx)
    {
        var res = tx.executeSql("SELECT url, count(DISTINCT uid) AS count " +
                                "FROM unread " +
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

/* Returns all cached unread items as a list of JSON strings.
 */
function cachedItems()
{
    var result = [];

    function f(tx)
    {
        var res = tx.executeSql("SELECT document FROM unread");
        for (var i = 0; i < res.rows.length; i++)
        {
            var data = res.rows.item(i);
            result.push(data.document);
        }
    }

    _database.transaction(f);
    return result;
}

/* Loads a list of {url, uid, document} records into the unread cache.
 */
function cacheItems(items)
{
    function f(tx)
    {
        console.log("caching " + items.length + " unread items");
        for (var i = 0; i < items.length; ++i)
        {
            tx.executeSql("INSERT INTO unread (url, uid, document) VALUES (?, ?, ?)",
                          [items[i].url, items[i].uid, items[i].document]);
        }
    }

    _database.transaction(f);
}

/* Returns all shelved items as a list of JSON strings.
 */
function shelvedItems()
{
    var result = [];

    function f(tx)
    {
        var res = tx.executeSql("SELECT document FROM shelf");
        for (var i = 0; i < res.rows.length; i++)
        {
            var data = res.rows.item(i);
            result.push(data.document);
        }
    }

    _database.transaction(f);
    return result;
}

/* Shelves the given item.
 */
function shelveItem(url, uid, document)
{
    function f(tx)
    {
        tx.executeSql("INSERT INTO shelf (url, uid, document) VALUES (?, ?, ?)",
                      [url, uid, document]);
    }

    _database.transaction(f);
}

/* Unshelves the given item.
 */
function unshelveItem(url, uid)
{
    function f(tx)
    {
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
