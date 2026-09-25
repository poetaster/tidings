#include "newsblendmodel.h"
#include "dateparser.h"
#include "database.h"

#include <QJsonDocument>
#include <QAbstractItemModel>
#include <QDebug>

namespace
{

int compare(NewsBlendModel::Item::ConstPtr a,
            NewsBlendModel::Item::ConstPtr b,
            NewsBlendModel::SortMode sortMode,
            const QString& selectedFeedSource)
{
    switch (sortMode)
    {
    case NewsBlendModel::LatestFirst:
        return (a->date < b->date) ? -1
                                   : (a->date == b->date) ? 0
                                                          : 1;
    case NewsBlendModel::OldestFirst:
        return (a->date < b->date) ? 1
                                   : (a->date == b->date) ? 0
                                                          : -1;
    case NewsBlendModel::FeedLatestFirst:
        if (a->feedSource == b->feedSource)
        {
            return (a->date < b->date) ? -1
                                       : (a->date == b->date) ? 0
                                                              : 1;
        }
        else
        {
            return (a->feedSource < b->feedSource) ? 1
                                                   : -1;
        }
    case NewsBlendModel::FeedOldestFirst:
        if (a->feedSource == b->feedSource)
        {
            return (a->date < b->date) ? 1
                                       : (a->date == b->date) ? 0
                                                              : -1;
        }
        else
        {
            return (a->feedSource < b->feedSource) ? 1
                                                   : -1;
        }
    case NewsBlendModel::FeedOnlyLatestFirst:
        if (a->feedSource != selectedFeedSource)
        {
            return -1;
        }
        else if (b->feedSource != selectedFeedSource)
        {
            return 1;
        }
        else
        {
            return (a->date < b->date) ? -1
                                       : (a->date == b->date) ? 0
                                                              : 1;
        }

    case NewsBlendModel::FeedOnlyOldestFirst:
        if (a->feedSource != selectedFeedSource)
        {
            return -1;
        }
        else if (b->feedSource != selectedFeedSource)
        {
            return 1;
        }
        else
        {
            return (a->date < b->date) ? 1
                                       : (a->date == b->date) ? 0
                                                              : -1;
        }

    default:
        return 0;
    }
}

/* The following functions are pure (no QObject access, no signals), so
 * they can safely run on the background thread.
 */

QList<NewsBlendModel::Enclosure> findEnclosures(const QVariantMap& itemData)
{
    QList<NewsBlendModel::Enclosure> enclosures;
    int amount = qMin(itemData.value("enclosuresAmount", 0).toInt(), 9);
    for (int i = 1; i <= amount; ++i)
    {
        NewsBlendModel::Enclosure enclosure;
        enclosure.url = itemData.value(QString("enclosure_%1_url")
                                       .arg(i)).toString();
        enclosure.size = itemData.value(QString("enclosure_%1_length")
                                       .arg(i), -1).toLongLong();

        QString type = itemData.value(QString("enclosure_%1_type")
                                      .arg(i)).toString();
        if (type.size())
        {
            enclosure.mimeType = type;
        }
        else if (enclosure.url.toLower().endsWith(".jpg") ||
                 enclosure.url.toLower().endsWith(".jpeg"))
        {
            enclosure.mimeType = "image/jpeg";
        }
        else if (enclosure.url.toLower().endsWith(".png"))
        {
            enclosure.mimeType = "image/png";
        }
        else
        {
            enclosure.mimeType = "application/octet-stream";
        }

        enclosures << enclosure;
    }
    return enclosures;
}

QString findThumbnail(const QVariantMap& itemData)
{
    QString thumbnail = itemData.value("iTunesImage").toString();

    if (thumbnail.isEmpty())
    {
        int minDelta = 9999;
        int goodWidth = 100;
        int amount = qMin(itemData.value("thumbnailsAmount", 0).toInt(), 9);
        for (int i = 1; i <= amount; ++i)
        {
            const QString url = itemData.value(QString("thumbnail_%1_url")
                                               .arg(i)).toString();
            int width = itemData.value(QString("thumbnail_%1_width")
                                       .arg(i), 0).toInt();

            if (qAbs(goodWidth - width) < minDelta)
            {
                minDelta = qAbs(goodWidth - width);
                thumbnail = url;
            }
        }
    }

    if (thumbnail.isEmpty())
    {
        foreach (const NewsBlendModel::Enclosure& enclosure, findEnclosures(itemData))
        {
            if (enclosure.mimeType.startsWith("image/"))
            {
                thumbnail = enclosure.url;
                break;
            }
        }
    }

    if (thumbnail.isEmpty())
    {
        // Atom feeds may have a thumbnail as link
        int amount = qMin(itemData.value("linksAmount", 0).toInt(), 5);
        for (int i = 1; i <= amount; ++i)
        {
            const QString href = itemData.value(QString("link_%1_href")
                                                .arg(i)).toString();
            const QString rel = itemData.value(QString("link_%1_rel")
                                               .arg(i)).toString();
            const QString type = itemData.value(QString("link_%1_type")
                                                .arg(i)).toString();
            if (rel == "enclosure" &&
                    (type == "image/jpeg" ||
                     type == "image/png"))
            {
                thumbnail = href;
                break;
            }
        }
    }

    return thumbnail;
}

QString findLink(const QVariantMap& itemData)
{
    QString link = itemData.value("link").toString();

    if (link.isEmpty())
    {
        int amount = qMin(itemData.value("linksAmount", 0).toInt(), 5);
        for (int i = 1; i <= amount; ++i)
        {
            const QString href = itemData.value(QString("link_%1_href")
                                                .arg(i)).toString();
            const QString rel = itemData.value(QString("link_%1_rel")
                                               .arg(i)).toString();
            if (rel == "alternate")
            {
                link = href;
                break;
            }
        }
    }
    return link;
}

NewsBlendModel::Item::Ptr parseItemData(const QVariantMap& itemData)
{
    NewsBlendModel::Item::Ptr item(new NewsBlendModel::Item);

    item->feedSource = itemData.value("source").toString();

    item->uid = itemData.value("uid").toString();
    item->date = itemData.value("date").toDateTime();

    // work around broken dates in cached data caused by a Qt 5.2 bug
    if (! item->date.isValid())
    {
        // dates may also be stored as strings
        item->date = QDateTime::fromString(itemData.value("date").toString(),
                                           Qt::ISODate);
    }
    if (! item->date.isValid())
    {
        DateParser dp;
        item->date = dp.parse(itemData.value("dateString").toString());
    }

    item->title = itemData.value("title").toString();
    item->title = item->title
            .replace("&apos;", "'")
            .replace("&quot;", "\"")
            .replace("&#38;", "&")
            .replace("&Auml;", "Ä")
            .replace("&Ouml;", "Ö")
            .replace("&Uuml;", "Ü")
            .replace("&auml;", "ä")
            .replace("&ouml;", "ö")
            .replace("&uuml;", "ü")
            .replace("&amp;", "&");

    item->link = findLink(itemData);

    item->mediaDuration = itemData.value("duration", 0).toLongLong();
    item->enclosures = findEnclosures(itemData);
    item->thumbnail = findThumbnail(itemData);

    item->isShelved = false;
    item->isRead = false;

    return item;
}

}

//
// PersistedLoader
//

PersistedLoader::PersistedLoader(QObject* parent)
    : QThread(parent)
{
}

void PersistedLoader::setDocuments(const QList<QByteArray>& cached,
                                   const QList<QByteArray>& shelved)
{
    myCached = cached;
    myShelved = shelved;
}

void PersistedLoader::run()
{
    // The documents were handed to this thread before start(); from here on
    // only this thread touches them, so parsing them here is safe.
    foreach (const QByteArray& document, myCached)
    {
        parseDocument(document, false);
    }
    foreach (const QByteArray& document, myShelved)
    {
        parseDocument(document, true);
    }
}

void PersistedLoader::parseDocument(const QByteArray& document, bool shelved)
{
    QJsonDocument doc = QJsonDocument::fromJson(document);
    if (! doc.isObject())
    {
        return;
    }

    QVariantMap itemData = doc.toVariant().toMap();
    NewsBlendModel::Item::Ptr item = parseItemData(itemData);
    if (! item)
    {
        return;
    }

    // remember the feed logo (first non-empty one wins)
    const QString logo = itemData.value("logo").toString();
    if (! logo.isEmpty() &&
            ! myResult.logos.contains(item->feedSource))
    {
        myResult.logos[item->feedSource] = logo;
    }

    if (shelved)
    {
        item->isShelved = true;
        item->isRead = true;
    }

    myResult.items << item;
}

NewsBlendModel::NewsBlendModel(QObject* parent)
    : QAbstractListModel(parent)
    , mySortMode(LatestFirst)
{
    myRolenames[FeedSourceRole] = "source";

    myRolenames[UidRole] = "uid";

    myRolenames[DateRole] = "date";

    myRolenames[TitleRole] = "title";

    myRolenames[LinkRole] = "link";

    myRolenames[ThumbnailRole] = "thumbnail";
    myRolenames[EnclosuresRole] = "enclosures";

    myRolenames[IsShelvedRole] = "shelved";
    myRolenames[IsReadRole] = "read";

    foreach (int key, myRolenames.keys())
    {
        myInverseRolenames[myRolenames[key]] = key;
    }
}

NewsBlendModel::~NewsBlendModel()
{
    if (myLoader)
    {
        // make sure the worker has finished before it (and its result
        // data) is destroyed
        myLoader->wait();
    }
}

void NewsBlendModel::reinsertItems()
{
    beginResetModel();
    myItems.clear();
    foreach (Item::Ptr item, myItemMap.values())
    {
        insertItem(item, false);
    }
    endResetModel();
    emit countChanged();
}

void NewsBlendModel::setSortMode(SortMode mode)
{
    if (mode != mySortMode)
    {
        qDebug() << Q_FUNC_INFO << mode;
        mySortMode = mode;
        reinsertItems();
        emit sortModeChanged();
        emit countChanged();
    }
}

void NewsBlendModel::setUnreadOnly(bool newUnreadOnly)
{
    if (newUnreadOnly != myUnreadOnly)
    {
        qDebug() << Q_FUNC_INFO << newUnreadOnly;
        myUnreadOnly = newUnreadOnly;
        reinsertItems();
        emit unreadOnlyChanged();
        emit countChanged();
    }
}

void NewsBlendModel::setSelectedFeed(const QString& selectedFeed)
{
    if (selectedFeed != mySelectedFeed)
    {
        mySelectedFeed = selectedFeed;
        emit selectedFeedChanged();
        if (mySortMode == FeedOnlyLatestFirst ||
            mySortMode == FeedOnlyOldestFirst)
        {
            reinsertItems();
            emit countChanged();
        }
    }
}

int NewsBlendModel::rowCount(const QModelIndex&) const
{
    if (mySortMode == FeedOnlyLatestFirst ||
            mySortMode == FeedOnlyOldestFirst)
    {
        if (myUnreadOnly) return myItems.size();
        else return myTotalCounts.value(mySelectedFeed, 0);
    }
    else
    {
        return myItems.size();
    }
}

QVariant NewsBlendModel::data(const QModelIndex& index, int role) const
{
    if (! index.isValid() || index.row() >= count())
    {
        return QVariant();
    }

    Item::ConstPtr item = myItems.at(index.row());

    switch (role)
    {
    case FeedSourceRole:
        return item->feedSource;
    case UidRole:
        return item->uid;
    case DateRole:
        return item->date;
    case TitleRole:
        return item->title;
    case LinkRole:
        return item->link;
    case MediaDurationRole:
        return item->mediaDuration;
    case ThumbnailRole:
        return item->thumbnail;
    case EnclosuresRole:
    {
        QVariantList enclosures;
        foreach (const Enclosure& e, item->enclosures)
        {
            QVariantMap enclosure;
            enclosure["url"] = e.url;
            enclosure["type"] = e.mimeType;
            enclosure["length"] = e.size;
            enclosures << enclosure;
        }
        return enclosures;
    }
    case IsShelvedRole:
        return item->isShelved;
    case IsReadRole:
        return item->isRead;
    default:
        return QVariant();
    }
}

int NewsBlendModel::insertItem(const Item::Ptr item, bool update)
{   
    int insertPos = -1;

    if ((myUnreadOnly && item->isRead) ||
            ((mySortMode == FeedOnlyLatestFirst ||
              mySortMode == FeedOnlyOldestFirst) &&
             item->feedSource != mySelectedFeed))
    {
        return insertPos;
    }

    if (myItems.size() > 0)
    {
        int begin = 0;
        int end = myItems.size() - 1;
        while (true)
        {
            if (begin == end)
            {
                if (compare(item, myItems.at(begin), mySortMode, mySelectedFeed) == -1)
                {
                    if (update)
                    {
                        //qDebug() << "insert" << (begin + 1) << myItems.size();
                        beginInsertRows(QModelIndex(), begin + 1, begin + 1);
                    }
                    insertPos = begin + 1;
                    myItems.insert(begin + 1, item);
                    if (update)
                    {
                        endInsertRows();
                    }
                }
                else
                {
                    if (update)
                    {
                        //qDebug() << "insert2" << begin << myItems.size();
                        beginInsertRows(QModelIndex(), begin, begin);
                    }
                    insertPos = begin;
                    myItems.insert(begin, item);
                    if (update)
                    {
                        endInsertRows();
                    }
                }
                break;
            }
            else
            {
                int middle = begin / 2 + end / 2;
                //qDebug() << "begin" << begin << "middle" << middle << "end" << end
                //         << "sortMode" << mySortMode;
                if (compare(item, myItems.at(middle), mySortMode, mySelectedFeed) == -1)
                {
                    begin = middle + 1;
                }
                else
                {
                    end = middle;
                }
            }
        }
    }
    else
    {
        if (update)
        {
            //qDebug() << "append" << myItems.size();
            beginInsertRows(QModelIndex(), myItems.size(), myItems.size());
        }
        insertPos = myItems.size();
        myItems << item;
        if (update)
        {
            endInsertRows();
        }
    }

    if (update)
    {
        emit countChanged();
    }

    return insertPos;
}

NewsBlendModel::Item::Ptr NewsBlendModel::parseItem(const QVariantMap& itemData) const
{
    return parseItemData(itemData);
}

QVariant NewsBlendModel::getAttribute(int idx, const QString& role) const
{
    return data(index(idx), myInverseRolenames.value(role.toUtf8(), 0));
}

void NewsBlendModel::loadItems(const QVariantList& jsons, bool shelved)
{
    mergeItems(jsons, shelved);
    reinsertItems();
}

void NewsBlendModel::mergeItems(const QVariantList& jsons, bool shelved)
{
    foreach (const QVariant& json, jsons)
    {
        QJsonDocument doc = QJsonDocument::fromJson(json.toByteArray());
        QVariantMap itemData = doc.toVariant().toMap();
        Item::Ptr item = parseItem(itemData);

        if (mySelectedFeed.isEmpty())
        {
            mySelectedFeed = item->feedSource;
        }

        if (myFeedLogos.value(item->feedSource).isEmpty())
        {
            myFeedLogos[item->feedSource] = itemData.value("logo").toString();
            //qDebug() << "Set logo" << myFeedLogos[item->feedSource];
        }

        FullId itemId(item->feedSource, item->uid);

        if (myItemMap.contains(itemId))
        {
            continue;
        }

        myTotalCounts[item->feedSource] =
                myTotalCounts.value(item->feedSource, 0) + 1;
        if (shelved)
        {
            item->isShelved = true;
            item->isRead = true;
        }
        else
        {
            myUnreadCounts[item->feedSource] =
                    myUnreadCounts.value(item->feedSource, 0) + 1;
        }
        myItemMap[itemId] = item;
    }
}

void NewsBlendModel::loadPersisted(Database* db)
{
    if (! db)
    {
        return;
    }

    if (myLoader)
    {
        // a load is already in progress; wait for it to finish before
        // starting a new one
        myLoader->wait();
        myLoader->deleteLater();
        myLoader = 0;
    }

    // Fetch all the documents on the main thread (the database is not
    // thread-safe) and hand them to the worker, which does the (slow)
    // JSON parsing off the GUI thread.
    PersistedLoader* loader = new PersistedLoader();
    loader->setDocuments(db->cachedDocuments(),
                         db->shelvedDocuments());

    connect(loader, SIGNAL(finished()),
            this, SLOT(persistedLoaderFinished()));

    myLoader = loader;
    myLoader->start();
}

void NewsBlendModel::persistedLoaderFinished()
{
    const PersistedLoader::Result& result = myLoader->result();

    // apply the feed logos collected by the worker
    foreach (const QString& feed, result.logos.keys())
    {
        if (myFeedLogos.value(feed).isEmpty())
        {
            myFeedLogos[feed] = result.logos[feed];
        }
    }

    // merge the parsed items into the item map. This is only bookkeeping
    // (no view updates), so it is cheap even for large collections.
    foreach (const Item::Ptr& item, result.items)
    {
        if (mySelectedFeed.isEmpty())
        {
            mySelectedFeed = item->feedSource;
        }

        FullId itemId(item->feedSource, item->uid);
        if (myItemMap.contains(itemId))
        {
            // keep the first occurrence
            continue;
        }

        myTotalCounts[item->feedSource] =
                myTotalCounts.value(item->feedSource, 0) + 1;
        if (! item->isShelved)
        {
            myUnreadCounts[item->feedSource] =
                    myUnreadCounts.value(item->feedSource, 0) + 1;
        }
        myItemMap[itemId] = item;
    }

    // all items are merged now, sort and update the view just once
    reinsertItems();

    if (! myReady)
    {
        myReady = true;
        emit readyChanged();
    }

    myLoader->deleteLater();
    myLoader = 0;
}

void NewsBlendModel::loadFromFeedModel(QObject* feedModel,
                                       const QString& feedSource,
                                       const QString& logo,
                                       Database* db)
{
    const QAbstractItemModel* model =
            qobject_cast<const QAbstractItemModel*>(feedModel);

    if (! model || ! db)
    {
        return;
    }

    QVariantList newItems;

    const QHash<int, QByteArray> roleNames = model->roleNames();

    for (int row = 0; row < model->rowCount(); ++row)
    {
        const QModelIndex modelIndex = model->index(row, 0);

        // read all properties of the feed model row
        QVariantMap itemData;
        foreach (int role, roleNames.keys())
        {
            itemData[QString::fromUtf8(roleNames.value(role))] =
                    model->data(modelIndex, role);
        }

        itemData.insert("source", feedSource);
        itemData.insert("logo", logo);

        // a valid date is needed for sorting; feeds that do not provide
        // one get the current time
        const QString dateString = itemData.value("dateString").toString();
        if (dateString.isEmpty())
        {
            itemData.insert("date", QDateTime::currentDateTime());
        }
        else
        {
            DateParser dp;
            itemData.insert("date", dp.parse(dateString));
        }

        // a uid is needed to deduplicate items; fall back to title + date
        if (itemData.value("uid").toString().isEmpty())
        {
            if (! dateString.isEmpty())
            {
                itemData.insert("uid",
                                itemData.value("title").toString()
                                + dateString);
            }
            else
            {
                itemData.insert("uid",
                                itemData.value("title").toString()
                                + QString::number(
                                    QDateTime::currentDateTime()
                                    .toMSecsSinceEpoch()));
            }
        }

        const QString uid = itemData.value("uid").toString();

        if (hasItem(feedSource, uid))
        {
            // do not insert the same item twice
            continue;
        }

        if (db->isRead(feedSource, uid) &&
                ! db->isShelved(feedSource, uid))
        {
            // read items are gone
            continue;
        }

        // insert into the model (it is guaranteed new, see the hasItem()
        // check above) and cache it as well
        addItem(itemData);

        {
            const QString encoded = itemData.value("encoded").toString();
            const QString body = encoded.length() > 0 ? encoded
                                                      : itemData.value("description").toString();

            // the body is stored separately; do not store it in the
            // cached document as well
            itemData.remove("description");
            itemData.remove("encoded");

            QVariantMap tuple;
            tuple.insert("url", feedSource);
            tuple.insert("uid", uid);
            tuple.insert("document",
                         QJsonDocument::fromVariant(itemData)
                         .toJson(QJsonDocument::Compact));
            tuple.insert("body", body);
            newItems.append(tuple);
        }
    }

    if (! newItems.isEmpty())
    {
        db->cacheItems(newItems);
    }
}

int NewsBlendModel::addItem(const QVariantMap& itemData, bool update)
{
    Item::Ptr item = parseItem(itemData);
    //qDebug() << "add item" << item->title;

    if (myFeedLogos.value(item->feedSource).isEmpty())
    {
        myFeedLogos[item->feedSource] = itemData.value("logo").toString();
    }

    FullId fullId(item->feedSource, item->uid);
    if (! myItemMap.contains(fullId))
    {
        myTotalCounts[item->feedSource] =
                myTotalCounts.value(item->feedSource, 0) + 1;
        myUnreadCounts[item->feedSource] =
                myUnreadCounts.value(item->feedSource, 0) + 1;

        myItemMap.insert(FullId(item->feedSource, item->uid), item);
        if (update)
        {
            return insertItem(item, update);
        }
    }

    return 0;
}

bool NewsBlendModel::hasItem(const QString& feedSource,
                             const QString& uid) const
{
    return myItemMap.contains(FullId(feedSource, uid));
}

void NewsBlendModel::setShelved(int idx, bool value)
{
    if (idx >= 0 && idx < myItems.size())
    {
        myItems[idx]->isShelved = value;
        emit shelvedChanged(idx);
        emit dataChanged(index(idx), index(idx),
                         QVector<int>() << IsShelvedRole);
    }
}

void NewsBlendModel::setRead(int idx, bool value)
{
    if (idx >= 0 &&
        idx < myItems.size() &&
        myItems[idx]->isRead != value)
    {
        myItems[idx]->isRead = value;
        myUnreadCounts[myItems[idx]->feedSource] += value ? -1 : 1;
        QVariantMap item;
        item["url"] = myItems[idx]->feedSource;
        item["uid"] = myItems[idx]->uid;
        item["value"] = value;
        emit readChanged(QVariantList() << item);
        emit dataChanged(index(idx), index(idx),
                         QVector<int>() << IsReadRole);
    }
}

void NewsBlendModel::setFeedRead(const QString& feedSource, bool value)
{
    QVariantList items;
    foreach (Item::Ptr item, myItemMap.values())
    {
        if (item->feedSource == feedSource &&
            item->isRead != value)
        {
            QVariantMap entry;
            entry["url"] = item->feedSource;
            entry["uid"] = item->uid;
            entry["value"] = value;
            items << entry;
            item->isRead = value;

            myUnreadCounts[feedSource] += value ? -1 : 1;
        }
    }

    int size = myItems.size();
    for (int i = 0; i < size; ++i)
    {
        if (myItems.at(i)->feedSource == feedSource)
        {
            emit dataChanged(index(i), index(i),
                             QVector<int>() << IsReadRole);
        }
    }

    emit readChanged(items);
}

void NewsBlendModel::setVisibleRead()
{
    QVariantList items;
    for (int i = 0; i < count(); ++i)
    {
        Item::Ptr item = myItems.at(i);
        if (! item->isRead)
        {
            QVariantMap entry;
            entry["url"] = item->feedSource;
            entry["uid"] = item->uid;
            entry["value"] = true;
            items << entry;
            item->isRead = true;
            emit dataChanged(index(i), index(i),
                             QVector<int>() << IsReadRole);

            --myUnreadCounts[item->feedSource];
        }
    }
    emit readChanged(items);
}

void NewsBlendModel::setAllRead()
{
    QVariantList items;
    foreach (Item::Ptr item, myItemMap.values())
    {
        if (! item->isRead && ! item->isShelved)
        {
            QVariantMap entry;
            entry["url"] = item->feedSource;
            entry["uid"] = item->uid;
            entry["value"] = true;
            items << entry;
            item->isRead = true;
        }
    }

    int size = myItems.size();
    for (int i = 0; i < size; ++i)
    {
        myItems[i]->isRead = true;
        emit dataChanged(index(i), index(i),
                         QVector<int>() << IsReadRole);
    }
    foreach (const QString& key, myUnreadCounts.keys())
    {
        myUnreadCounts[key] = 0;
    }
    emit readChanged(items);
}

void NewsBlendModel::removeReadItems(const QString& feedSource)
{
    foreach (Item::Ptr item, myItemMap.values())
    {
        if (item->isRead && ! item->isShelved &&
                (feedSource.isEmpty() || item->feedSource == feedSource))
        {
            if (myItemMap.remove(FullId(item->feedSource, item->uid)))
            {
                qDebug() << "removed item" << item->title;
                --myTotalCounts[item->feedSource];
            }
        }
    }
    reinsertItems();
}

void NewsBlendModel::removeFeedItems(const QString& feedSource)
{
    foreach (Item::Ptr item, myItemMap)
    {
        if (item->feedSource == feedSource)
        {
            myItemMap.remove(FullId(item->feedSource, item->uid));
        }
    }
    myTotalCounts.remove(feedSource);
    myUnreadCounts.remove(feedSource);
    reinsertItems();
}

int NewsBlendModel::previousOfFeed(int index) const
{
    if (index < myItems.size())
    {
        const QString feedSource = myItems.at(index)->feedSource;
        --index;
        while (index >= 0)
        {
            if (myItems.at(index)->feedSource == feedSource)
            {
                return index;
            }
            --index;
        }
    }
    return -1;
}

int NewsBlendModel::nextOfFeed(int index) const
{
    int size = count();
    if (index < size)
    {
        const QString feedSource = myItems.at(index)->feedSource;
        ++index;
        while (index < size)
        {
            if (myItems.at(index)->feedSource == feedSource)
            {
                return index;
            }
            ++index;
        }
    }
    return -1;
}

int NewsBlendModel::firstOfFeed(const QString& feedSource) const
{
    int size = count();
    for (int i = 0; i < size; ++i)
    {
        if (myItems.at(i)->feedSource == feedSource)
        {
            return i;
        }
    }
    return -1;
}

QString NewsBlendModel::logoOfFeed(const QString& feedSource) const
{
    return myFeedLogos.value(feedSource);
}

QStringList NewsBlendModel::thumbnailsOfFeed(const QString& feedSource) const
{
    QStringList result;
    foreach (Item::ConstPtr item, myItemMap.values())
    {
        if (item->feedSource == feedSource && item->thumbnail.size())
        {
            result << item->thumbnail;
        }
    }
    return result;
}

QVariantMap NewsBlendModel::totalStats() const
{
    QVariantMap stats;
    foreach (const QString& feedSource, myTotalCounts.keys())
    {
        stats[feedSource] = myTotalCounts[feedSource];
    }
    return stats;
}

QVariantMap NewsBlendModel::unreadStats() const
{
    QVariantMap stats;
    foreach (const QString& feedSource, myUnreadCounts.keys())
    {
        stats[feedSource] = myUnreadCounts[feedSource];
    }
    return stats;
}
