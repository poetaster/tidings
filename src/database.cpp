#include "database.h"

#include <QDir>
#include <QSqlQuery>
#include <QStandardPaths>

#include <QDebug>

Database::Database(QObject* parent)
    : QObject(parent)
{
    myDb = QSqlDatabase::addDatabase("QSQLITE");

    const QString db = locateDatabase();
    if (! db.isEmpty())
    {
        myDb.setDatabaseName(db);
        myDb.open();
    }
}

QString Database::locateDatabase()
{
    const QStringList dataPaths = QStandardPaths::standardLocations(
                QStandardPaths::DataLocation);

    foreach (const QString& path, dataPaths)
    {
        qDebug() << "Looking for database in" << path;
        const QString dbPath =
                QDir(path).filePath("QML/OfflineStorage/Databases");
        const QDir dbDir(dbPath);
        if (dbDir.exists())
        {
            foreach (const QString& fileName, dbDir.entryList())
            {
                if (fileName.endsWith(".sqlite"))
                {
                    // this is the file
                    return dbDir.absoluteFilePath(fileName);
                }
            }
        }
    }
    return QString();
}

void Database::vacuum()
{
    if (myDb.isOpen())
    {
        qDebug() << "Vacuuming database... *vrooom*";
        myDb.exec("VACUUM");
        qDebug() << "Done.";
    }
}
