#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>

class QSqlDatabase;

class Database : public QObject
{
    Q_OBJECT
public:
    explicit Database(QObject* parent = 0);

    Q_INVOKABLE void vacuum();

private:
    QString locateDatabase();

private:
    QSqlDatabase myDb;
};

#endif // DATABASE_H
