.import QtQuick.LocalStorage 2.0 as Sql

var _REVISION = 1;

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
    }

    // set the new revision
    if (revision === 0) {
        tx.executeSql("INSERT INTO status (keyname, value) VALUES (?, ?)",
                      ["revision", _REVISION]);
    } else {
        tx.executeSql("UPDATE status SET value = ? WHERE keyname = ?",
                      [_REVISION, "revision"]);
    }
}

/* Migrates to Rev 1.
 */
function _migrateRev1(tx) {
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

/* Creates the initial schema.
 */
function _createSchema(tx) {
    tx.executeSql("CREATE TABLE sources (" +
                  "  sourceid INT," +
                  "  name TEXT," +
                  "  url TEXT" +
                  ")");
}

/* Returns the feed sources.
 */
function sources() {

    var result = [];

    function f(tx) {
        var res = tx.executeSql("SELECT sourceid, name, url FROM sources");
        for (var i = 0; i < res.rows.length; i++)
        {
            var item = res.rows.item(i);
            result.push({
                            "sourceId": item.sourceid,
                            "name": item.name,
                            "url": item.url
                        });
        }
        console.log("feeds loaded");
    }

    _database.transaction(f);
    return result;
}

/* Adds a new feed source.
 */
function addSource(name, url) {

    var nextId = 0;

    function f(tx) {
        var res = tx.executeSql("SELECT max(sourceid) as sourceid FROM sources");
        if (res.rows.length) {
            nextId = res.rows.item(0).sourceid + 1;
        } else {
            nextId = 0;
        }
        tx.executeSql("INSERT INTO sources (sourceid, name, url) VALUES (?, ?, ?)",
                      [nextId, name, url]);
    }

    _database.transaction(f);
    return nextId;
}

/* Changes a feed source.
 */
function changeSource(sourceId, name, url) {

    function f(tx) {
        tx.executeSql("UPDATE sources SET name = ?, url = ? WHERE sourceid = ?",
                      [name, url, sourceId]);
    }

    _database.transaction(f);
}

/* Removes a feed source.
 */
function removeSource(sourceId) {

    function f(tx) {
        tx.executeSql("DELETE FROM sources WHERE sourceid = ?",
                      [sourceId]);
    }

   _database.transaction(f);
}
