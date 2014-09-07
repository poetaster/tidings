#include "htmlfilter.h"

#include <QMap>
#include <QRegExp>
#include <QStringList>
#include <QDebug>

namespace
{

const QRegExp RE_TAG("<[^>]+>");
const QRegExp RE_TAG_NAME("[a-zA-Z0-9]+[\\s/>]");
const QRegExp RE_TAG_ATTRIBUTE("[a-zA-Z0-9]+\\s*=\\s*(\"[^\"]*\"|'[^']*'|[^\\s\"']*)");

const QRegExp RE_STYLE_COLOR("color:\\s*[^\\s;\"']+;?");
const QRegExp RE_STYLE_FONT_SIZE("font-size:\\s*\\d+[a-zA-Z]*;?");

QString findTag(const QString& html, int& pos)
{
    QRegExp tag(RE_TAG);
    pos = tag.indexIn(html);
    if (pos != -1)
    {
        int length = tag.matchedLength();
        return html.mid(pos, length);
    }
    else
    {
        return QString();
    }
}

class Tag
{
public:
    Tag(const QString& data);

    bool isOpening() const { return myIsOpening; }
    bool isClosing() const { return myIsClosing; }
    QString name() const { return myName; }
    QStringList attributes() const { return myAttributes.keys(); }
    bool hasAttribute(const QString& attr) const
    {
        return myAttributes.contains(attr.toUpper());
    }
    QString attribute(const QString& attr)
    {
        return myAttributes.value(attr.toUpper());
    }
    void setAttribute(const QString& attr, const QString& value)
    {
        myAttributes[attr.toUpper()] = value;
    }
    QString toString() const;

private:
    bool myIsOpening;
    bool myIsClosing;
    QString myName;
    QMap<QString, QString> myAttributes;
};

Tag::Tag(const QString& data)
    : myIsOpening(false)
    , myIsClosing(false)
{
    qDebug() << "TAG" << data;

    if (data.trimmed().startsWith("</"))
    {
        myIsClosing = true;
    }
    else
    {
        myIsOpening = true;
    }
    if (data.trimmed().endsWith("/>"))
    {
        myIsClosing = true;
    }


    QRegExp tagName(RE_TAG_NAME);
    int pos = tagName.indexIn(data);

    if (pos == -1)
    {
        return;
    }

    int length = tagName.matchedLength();
    myName = data.mid(pos, tagName.matchedLength() - 1).trimmed().toUpper();
    qDebug() << "NAME" << myName;

    int offset = pos + length;

    QRegExp tagAttribute(RE_TAG_ATTRIBUTE);
    while (true)
    {
        int attrPos = tagAttribute.indexIn(data.mid(offset));
        if (attrPos == -1)
        {
            break;
        }
        const QString attr = data.mid(offset + attrPos,
                                      tagAttribute.matchedLength());
        if (attr.isEmpty())
        {
            break;
        }
        offset += attrPos + tagAttribute.matchedLength();
        qDebug() << "ATTR" << attr;

        int splitPos = attr.indexOf('=');
        if (splitPos != -1)
        {
            const QString attrName = attr.left(splitPos).trimmed().toUpper();
            QString attrValue = attr.mid(splitPos + 1).trimmed();
            if (attrValue.startsWith("'") || attrValue.startsWith("\""))
            {
                attrValue = attrValue.mid(1, attrValue.size() - 2);
            }
            myAttributes[attrName] = attrValue;
        }
    }

}

QString Tag::toString() const
{
    QString out = "<";
    if (! myIsOpening && myIsClosing)
    {
        out += "/";
    }
    out += myName;

    foreach (const QString& attr, myAttributes.keys())
    {
        out += " " + attr + "=\"" + myAttributes.value(attr) + "\"";
    }

    if (myIsOpening && myIsClosing)
    {
        out += "/";
    }
    out += ">";

    return out;
}

}

HtmlFilter::HtmlFilter(QObject* parent)
    : QObject(parent)
{

}

QString HtmlFilter::filter(const QString& html) const
{
    QString s = html;

    int offset = 0;
    int pos = 0;

    while (true)
    {
        const QString tagData = findTag(s.mid(offset), pos);
        if (tagData.isEmpty())
        {
            break;
        }

        bool dropTag = false;
        bool replaceTag = false;

        Tag tag(tagData);
        if (tag.hasAttribute("STYLE"))
        {
            QString style = tag.attribute("STYLE");
            qDebug() << "STYLE BEFORE" << style;
            style.replace(RE_STYLE_COLOR, "");
            style.replace(RE_STYLE_FONT_SIZE, "");
            qDebug() << "STYLE AFTER" << style;
            tag.setAttribute("STYLE", style);
            replaceTag = true;
        }

        if (replaceTag)
        {
            const QString& newTag = tag.toString();
            s.replace(offset + pos, tagData.size(), newTag);
            offset += pos + newTag.size();
        }
        else if (dropTag)
        {
            s.replace(offset + pos, tagData.size(), "");
            offset += pos;
        }
        else
        {
            offset += pos + tagData.size();
        }
    }

    return s;
}

