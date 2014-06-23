#include "newsblendmodel.h"

#include <QJsonDocument>
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
            return (a->feedSource < b->feedSource) ? 1
                                                   : -1;
        }

    default:
        return 0;
    }
}

}

NewsBlendModel::NewsBlendModel(QObject* parent)
    : QAbstractListModel(parent)
    , mySortMode(LatestFirst)
{
    myRolenames[FeedSourceRole] = "source";

    myRolenames[UidRole] = "uid";

    myRolenames[SectionTitleRole] = "sectionTitle";
    myRolenames[DateRole] = "date";

    myRolenames[TitleRole] = "title";
    myRolenames[BodyRole] = "body";

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

void NewsBlendModel::setSortMode(SortMode mode)
{
    qDebug() << Q_FUNC_INFO << mode;
    mySortMode = mode;

    beginResetModel();
    myItems.clear();
    foreach (Item::Ptr item, myItemMap.values())
    {
        insertItem(item, false);
    }
    endResetModel();

    emit sortModeChanged();
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
            setSortMode(mySortMode);
        }
    }
}

int NewsBlendModel::rowCount(const QModelIndex&) const
{
    if (mySortMode == FeedOnlyLatestFirst ||
            mySortMode == FeedOnlyOldestFirst)
    {
        return myTotalCounts.value(mySelectedFeed, 0);
    }
    else
    {
        return myItems.size();
    }
}

QVariant NewsBlendModel::data(const QModelIndex& index, int role) const
{
    if (! index.isValid() || index.row() >= myItems.size())
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
    case SectionTitleRole:
        return item->sectionTitle;
    case DateRole:
        return item->date;
    case TitleRole:
        return item->title;
    case BodyRole:
        return item->body;
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

    emit sectionTitleRequested(item->feedSource, item->date);
    item->sectionTitle = myCurrentSectionTitle;
    //qDebug() << "section title:" << item->sectionTitle;

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

QList<NewsBlendModel::Enclosure> NewsBlendModel::findEnclosures(const QVariantMap& itemData) const
{
    QList<Enclosure> enclosures;
    int amount = qMin(itemData.value("enclosuresAmount", 0).toInt(), 9);
    for (int i = 1; i <= amount; ++i)
    {
        Enclosure enclosure;
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

QString NewsBlendModel::findThumbnail(const QVariantMap& itemData) const
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
        foreach (const Enclosure& enclosure, findEnclosures(itemData))
        {
            if (enclosure.mimeType.startsWith("image/"))
            {
                thumbnail = enclosure.url;
                break;
            }
        }
    }

    return thumbnail;
}

NewsBlendModel::Item::Ptr NewsBlendModel::parseItem(const QVariantMap& itemData) const
{
    Item::Ptr item(new Item);

    item->rawData = itemData;

    // will be set when inserting
    item->sectionTitle = "unknown";

    item->feedSource = itemData.value("source").toString();

    item->uid = itemData.value("uid").toString();
    item->date = itemData.value("date").toDateTime();

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

    const QString description = itemData.value("description").toString();
    // defuse styles until we have more sophisticated HTML normalizing
    const QString encoded = itemData.value("encoded").toString()
            .replace(" style=", " xstyle=");
    item->body = encoded.size() ? encoded : description;

    item->link = itemData.value("link").toString();

    item->mediaDuration = itemData.value("duration", 0).toLongLong();
    item->enclosures = findEnclosures(itemData);
    item->thumbnail = findThumbnail(itemData);

    item->isShelved = false;
    item->isRead = false;

    return item;
}

QVariant NewsBlendModel::getAttribute(int idx, const QString& role) const
{
    return data(index(idx), myInverseRolenames.value(role.toUtf8(), 0));
}

QString NewsBlendModel::toJson(int index) const
{
    qDebug() << Q_FUNC_INFO << index;
    if (index >= 0 && index < myItems.size())
    {
        QJsonDocument doc = QJsonDocument::fromVariant(myItems.at(index)->rawData);
        return QString::fromUtf8(doc.toJson());
    }
    else
    {
        return QString();
    }
}

void NewsBlendModel::loadItems(const QVariantList& jsons, bool shelved)
{
    foreach (const QVariant& json, jsons)
    {
        QJsonDocument doc = QJsonDocument::fromJson(json.toByteArray());
        QVariantMap itemData = doc.toVariant().toMap();
        Item::Ptr item = parseItem(itemData);

        if (myFeedLogos.value(item->feedSource).isEmpty())
        {
            myFeedLogos[item->feedSource] = itemData.value("logo").toString();
            qDebug() << "Set logo" << myFeedLogos[item->feedSource];
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
        myItemMap[FullId(item->feedSource, item->uid)] = item;
    }
    setSortMode(mySortMode);
}

int NewsBlendModel::addItem(const QVariantMap& itemData, bool update)
{
    Item::Ptr item = parseItem(itemData);
    //qDebug() << "add item" << item->title;

    if (myFeedLogos.value(item->feedSource).isEmpty())
    {
        myFeedLogos[item->feedSource] = itemData.value("logo").toString();
    }

    myTotalCounts[item->feedSource] =
            myTotalCounts.value(item->feedSource, 0) + 1;
    myUnreadCounts[item->feedSource] =
            myUnreadCounts.value(item->feedSource, 0) + 1;

    myItemMap.insert(FullId(item->feedSource, item->uid), item);
    if (update)
    {
        return insertItem(item, update);
    }
    else
    {
        return 0;
    }
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
    if (idx >= 0 && idx < myItems.size())
    {
        myItems[idx]->isRead = value;
        --myUnreadCounts[myItems[idx]->feedSource];
        emit readChanged(QList<int>() << idx);
        emit dataChanged(index(idx), index(idx),
                         QVector<int>() << IsReadRole);
    }
}

void NewsBlendModel::setFeedRead(const QString& feedSource)
{
    QList<int> indexes;
    int size = myItems.size();
    for (int i = 0; i < size; ++i)
    {
        if (myItems.at(i)->feedSource == feedSource &&
            ! myItems.at(i)->isRead)
        {
            myItems[i]->isRead = true;
            indexes << i;
            emit dataChanged(index(i), index(i),
                             QVector<int>() << IsReadRole);
        }
    }
    myUnreadCounts[feedSource] = 0;
    emit readChanged(indexes);
}

void NewsBlendModel::setAllRead()
{
    QList<int> indexes;
    int size = myItems.size();
    for (int i = 0; i < size; ++i)
    {
        if (! myItems.at(i)->isRead)
        {
            myItems[i]->isRead = true;
            indexes << i;
            emit dataChanged(index(i), index(i),
                             QVector<int>() << IsReadRole);
        }
    }
    foreach (const QString& key, myUnreadCounts.keys())
    {
        myUnreadCounts[key] = 0;
    }
    emit readChanged(indexes);
}

void NewsBlendModel::removeReadItems(const QString& feedSource)
{
    beginResetModel();
    int pos = 0;
    while (pos < myItems.size())
    {
        Item::Ptr item = myItems.at(pos);
        if (item->isRead &&
                ! item->isShelved &&
                (feedSource.isEmpty() || item->feedSource == feedSource))
        {
            Item::Ptr item = myItems.takeAt(pos);
            myItemMap.remove(FullId(item->feedSource, item->uid));

            --myTotalCounts[feedSource];
        }
        else
        {
            ++pos;
        }
    }
    endResetModel();
}

void NewsBlendModel::removeFeedItems(const QString& feedSource)
{
    beginResetModel();
    int pos = 0;
    while (pos < myItems.size())
    {
        if (myItems.at(pos)->feedSource == feedSource &&
            ! myItems.at(pos)->isShelved)
        {
            Item::Ptr item = myItems.takeAt(pos);
            myItemMap.remove(FullId(item->feedSource, item->uid));

            --myTotalCounts[feedSource];
            if (! item->isRead)
            {
                --myUnreadCounts[feedSource];
            }
        }
        else
        {
            ++pos;
        }
    }
    endResetModel();
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
    if (index < myItems.size())
    {
        const QString feedSource = myItems.at(index)->feedSource;
        ++index;
        while (index < myItems.size())
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
    int size = myItems.size();
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
    int size = myItems.size();
    for (int i = 0; i < size; ++i)
    {
        if (myItems.at(i)->feedSource == feedSource &&
            myItems.at(i)->thumbnail.size())
        {
            result << myItems.at(i)->thumbnail;
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
