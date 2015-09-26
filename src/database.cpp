#include "database.h"

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
}

QString Database::locateDatabase()
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
        return QDir(dataPaths.at(1)).absoluteFilePath(DATABASE);
    }
    else
    {
        return QString();
    }
}

void Database::vacuum()
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
