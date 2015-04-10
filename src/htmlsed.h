#ifndef HTMLSED_H
#define HTMLSED_H

#include <QList>
#include <QMap>
#include <QRegExp>
#include <QString>
#include <QStringList>


/* Class for a HTML stream editor to manipulate HTML documents according to
 * a set of rules.
 */
class HtmlSed
{
public:
    class Tag
    {
    public:
        Tag(const QString& data);

        bool isModified() const { return myIsModified; }
        bool isOpening() const { return myIsOpening; }
        bool isClosing() const { return myIsClosing; }
        bool isHidden() const { return myIsHidden; }
        void setHidden(bool value)
        {
            myIsHidden = value;
        }
        QString name() const { return myName; }
        void setName(const QString& name)
        {
            myName = name;
            myIsModified = true;
        }
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
            myIsModified = true;
        }
        void removeAttribute(const QString& attr)
        {
            myAttributes.remove(attr.toUpper());
        }
        void replaceWith(const QString& replaceWith)
        {
            myReplaceWith = replaceWith;
            myIsReplaced = true;
            myIsModified = true;
        }
        void setSurroundings(const QString& before, const QString& after)
        {
            myBeforeText = before;
            myAfterText = after;
            myIsModified = true;
        }

        QString toString() const;

    private:
        bool myIsModified;
        bool myIsOpening;
        bool myIsClosing;
        bool myIsHidden;
        QString myName;
        QMap<QString, QString> myAttributes;
        bool myIsReplaced;
        QString myReplaceWith;
        QString myBeforeText;
        QString myAfterText;
    };

    class Modifier
    {
    public:
        virtual void modifyTag(HtmlSed::Tag& tag) = 0;
    };

    HtmlSed(const QString& html);
    QString toString() const;

    void replaceTag(const QString& tagToReplace,
                    const QString& replaceWith,
                    bool openingTag = true,
                    bool closingTag = true);

    void replaceAttribute(const QString& tagToReplace,
                          const QString& attributeToReplace,
                          const QString& replaceWith);

    void replaceContents(const QString& enclosingTag,
                         const QString& replaceWith);

    void surroundTag(const QString& tag,
                     const QString& before,
                     const QString& after,
                     bool openingTag = true,
                     bool closingTag = true);

    void dropTag(const QString& tagToDrop)
    {
        replaceTag(tagToDrop, QString());
    }

    void dropTagWithContents(const QString& tagToDrop)
    {
        replaceContents(tagToDrop, QString());
    }

    void resolveUrl(const QString& tagToResolve,
                    const QString& attributeToResolve,
                    const QString& baseUrl);

    void modifyTag(const QString& tag,
                   Modifier* modifier);

private:
    struct Rule
    {
        enum Mode
        {
            REPLACE_ATTRIBUTE,
            REPLACE_TAG,
            REPLACE_CONTENTS,
            RESOLVE_URL,
            SURROUND_TAG,
            MODIFY_TAG
        };

        void replaceTag(const QString& t,
                        const QString& w,
                        bool o,
                        bool c);

        void replaceAttribute(const QString& t,
                              const QString& a,
                              const QString& w);

        void replaceContents(const QString& t,
                             const QString& w);

        void resolveUrl(const QString& t,
                        const QString& a,
                        const QString& u);

        void surroundTag(const QString& t,
                         const QString& b,
                         const QString& a,
                         bool o,
                         bool c);

        void modifyTag(const QString& t,
                       Modifier* m);

        Mode mode;
        QString tag;
        QString attribute;
        QString replaceWith;
        QString replaceWithAfter;
        QString resolveBaseUrl;
        bool openingTag;
        bool closingTag;
        Modifier* tagModifier;
    };

    void addRule(const QString& tag, const HtmlSed::Rule& rule);

private:
    QString myHtml;
    QMap<QString, QList<HtmlSed::Rule> > myRuleSet;
};

#endif // HTMLSED_H
