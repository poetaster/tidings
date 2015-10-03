#include "htmlsed.h"

#include <QUrl>
#include <QDebug>

namespace
{

const QRegExp RE_TAG_NAME("[a-zA-Z0-9]+[\\s/>]");
const QRegExp RE_TAG_ATTRIBUTE("[a-zA-Z0-9]+\\s*=\\s*(\"[^\"]*\"|'[^']*'|[^\\s\"']*)");
// regex to verify proper quoting in a HTML tag
const QRegExp RE_QUOTES("([^\"']*(\"[^\"]*\"|'[^']*')?[^\"']*)*");

// expressions to desperately try to make some sense out of malformed HTML code
const QRegExp RE_ATTR_EQ_QUOTE_STRING_QUOTE("[a-zA-Z0-9\\-]+\\s*=\\s*\"[^\"]*\"");
const QRegExp RE_ATTR_EQ_APOS_STRING_APOS("[a-zA-Z0-9\\-]+\\s*=\\s*\'[^\']*\'");
const QRegExp RE_ATTR_EQ_STRING_QUOTE("[a-zA-Z0-9\\-]+\\s*=\\s*[^\"=]*\"");
const QRegExp RE_ATTR_EQ_STRING_APOS("[a-zA-Z0-9\\-]+\\s*=\\s*[^\'=]*\'");
const QRegExp RE_ATTR_EQ_NOSPACESTRING("[a-zA-Z0-9\\-]+\\s*=\\s*[^\\s]+");
const QRegExp RE_ATTR_EQ("[a-zA-Z0-9\\-]+\\s*=\\s*");
const QRegExp RE_ATTR_ONLY("[a-zA-Z0-9\\-]+\\s*");


/* Attempts to repair a malformed tag.
 * Hello Engadget, this is for your sloppy HTML code!
 */
QString repairMalformedTag(const QString& badCode)
{
    int offset = 0;
    QString code = badCode;

    // consume '<'
    ++offset;

    // consume white space
    while (offset < code.size() && code.at(offset) == ' ')
    {
        ++offset;
    }

    // consume tag name, if any
    while (offset < code.size() && code.at(offset).isLetterOrNumber())
    {
        ++offset;
    }

    while (offset < code.size())
    {
        // consume white space
        while (offset < code.size() && code.at(offset) == ' ')
        {
            ++offset;
        }

        if (offset < code.size() && code.at(offset) == '/')
        {
            // closing tag
            break;
        }

        if (RE_ATTR_EQ_QUOTE_STRING_QUOTE.indexIn(code, offset) == offset)
        {
            // clean
            offset += RE_ATTR_EQ_QUOTE_STRING_QUOTE.matchedLength();
        }
        else if (RE_ATTR_EQ_APOS_STRING_APOS.indexIn(code, offset) == offset)
        {
            // clean
            offset += RE_ATTR_EQ_APOS_STRING_APOS.matchedLength();
        }
        else if (RE_ATTR_EQ_STRING_QUOTE.indexIn(code, offset) == offset)
        {
            // missing first quote, insert it
            int pos = code.indexOf('=', offset);
            code = code.insert(pos + 1, '"');
            offset += RE_ATTR_EQ_STRING_QUOTE.matchedLength() + 1;
            qDebug() << "inserted missing first quote";
        }
        else if (RE_ATTR_EQ_STRING_APOS.indexIn(code, offset) == offset)
        {
            // missing first apostrophe, insert it
            int pos = code.indexOf('=', offset);
            code = code.insert(pos + 1, '\'');
            offset += RE_ATTR_EQ_STRING_APOS.matchedLength() + 1;
            qDebug() << "inserted missing first apostrophe";
        }
        else if (RE_ATTR_EQ_NOSPACESTRING.indexIn(code, offset) == offset)
        {
            // missing quotes, insert them
            int pos = code.indexOf('=', offset);
            code = code.insert(pos + 1, '"');
            code = code.insert(offset + RE_ATTR_EQ_NOSPACESTRING.matchedLength() + 1, '"');
            offset += RE_ATTR_EQ_NOSPACESTRING.matchedLength() + 2;
            qDebug() << "inserted missing quotes";
        }
        else if (RE_ATTR_EQ.indexIn(code, offset) == offset)
        {
            // missing string, insert quotes
            code = code.insert(RE_ATTR_EQ.matchedLength(), "\"\"");
            offset += RE_ATTR_EQ.matchedLength() + 2;
            qDebug() << "inserted missing string";
        }
        else if (RE_ATTR_ONLY.indexIn(code, offset) == offset)
        {
            // clean
            offset += RE_ATTR_ONLY.matchedLength();
        }
        else
        {
            // what's that?
            break;
        }
    }
    if (code.size() != badCode.size())
    {
        qDebug() << "Repaired: " << badCode << "->" << code;
    }
    return code;
}

/* Finds and returns the next tag in the given HTML string.
 * HTML comments (<!-- -->) are recognized as tags.
 * pos will be set to the start position of the tag in the string.
 */
QString findTag(const QString& html, int offset, int& pos)
{
    int bracketPos = html.indexOf("<", offset);
    if (bracketPos == -1)
    {
        return QString();
    }

    if (html.mid(bracketPos, 4) == "<!--")
    {
        // it's a comment
        int commentEndPos = html.indexOf("-->", bracketPos);
        if (commentEndPos != -1)
        {
            pos = bracketPos - offset;
            int length = commentEndPos + 3 - bracketPos;
            return html.mid(bracketPos, length);
        }
    }
    else
    {
        int searchPos = bracketPos;
        while (true)
        {
            int endPos = html.indexOf(">", searchPos);
            //qDebug() << "endPos" << endPos << html.size();
            if (endPos != -1)
            {
                int length = endPos + 1 - bracketPos;
                QString part = html.mid(bracketPos, length);
                //qDebug() << part;
                part = repairMalformedTag(part);
                if (RE_QUOTES.exactMatch(part))
                {
                    pos = bracketPos - offset;
                    return part;
                }
                else
                {
                    searchPos = endPos + 1;
                }
            }
            else
            {
                // reached EOF
                break;
            }
        }

        /*
        int endPos = html.indexOf(">", bracketPos);
        if (endPos != -1)
        {
            pos = bracketPos - offset;
            int length = endPos + 1 - bracketPos;
            return html.mid(bracketPos, length);
        }
        */
    }

    return QString();
}

}


HtmlSed::Tag::Tag(const QString& data)
    : myIsModified(false)
    , myIsOpening(false)
    , myIsClosing(false)
    , myIsHidden(false)
    , myIsReplaced(false)
{
    //qDebug() << "TAG" << data;

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
    //qDebug() << "NAME" << myName;

    if (myName == "IMG" ||
            myName == "BR" ||
            myName == "HR")
    {
        myIsClosing = true;
    }


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
        //qDebug() << "ATTR" << attr;

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

QString HtmlSed::Tag::toString() const
{
    if (myIsReplaced)
    {
        return myBeforeText + myReplaceWith + myAfterText;
    }

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

    return myBeforeText + out + myAfterText;
}




void HtmlSed::Rule::replaceTag(const QString& t,
                               const QString& w,
                               bool o,
                               bool c)
{
    mode = REPLACE_TAG;
    tag = t;
    replaceWith = w;
    openingTag = o;
    closingTag = c;
}

void HtmlSed::Rule::replaceAttribute(const QString& t,
                                     const QString& a,
                                     const QString& w)
{
    mode = REPLACE_ATTRIBUTE;
    tag = t;
    attribute = a;
    replaceWith = w;
}

void HtmlSed::Rule::replaceContents(const QString& t,
                                    const QString& w)
{
    mode = REPLACE_CONTENTS;
    tag = t;
    replaceWith = w;
}

void HtmlSed::Rule::resolveUrl(const QString& t,
                               const QString& a,
                               const QString& u)
{
    mode = RESOLVE_URL;
    tag = t;
    attribute = a;
    resolveBaseUrl = u;
}

void HtmlSed::Rule::surroundTag(const QString& t,
                                const QString& b,
                                const QString& a,
                                bool o,
                                bool c)
{
    mode = SURROUND_TAG;
    tag = t;
    replaceWith = b;
    replaceWithAfter = a;
    openingTag = o;
    closingTag = c;
}

void HtmlSed::Rule::modifyTag(const QString& t,
                              Modifier* m)
{
    mode = MODIFY_TAG;
    tag = t;
    tagModifier = m;
}



HtmlSed::HtmlSed(const QString& html)
    : myHtml(html)
{

}

void HtmlSed::addRule(const QString& tag, const HtmlSed::Rule& rule)
{
    if (! myRuleSet.contains(tag))
    {
        myRuleSet[tag] = QList<Rule>();
    }
    myRuleSet[tag] << rule;
}

void HtmlSed::replaceTag(const QString& tagToReplace,
                         const QString& replaceWith,
                         bool openingTag,
                         bool closingTag)
{
    Rule rule;
    rule.replaceTag(tagToReplace,
                    replaceWith,
                    openingTag,
                    closingTag);
    addRule(tagToReplace, rule);
}

void HtmlSed::replaceAttribute(const QString& tagToReplace,
                               const QString& attributeToReplace,
                               const QString& replaceWith)
{
    Rule rule;
    rule.replaceAttribute(tagToReplace,
                          attributeToReplace,
                          replaceWith);
    addRule(tagToReplace, rule);
}

void HtmlSed::replaceContents(const QString& enclosingTag,
                              const QString& replaceWith)
{
    Rule rule;
    rule.replaceContents(enclosingTag,
                         replaceWith);
    addRule(enclosingTag, rule);
}

void HtmlSed::surroundTag(const QString& tag,
                          const QString& before,
                          const QString& after,
                          bool openingTag,
                          bool closingTag)
{
    Rule rule;
    rule.surroundTag(tag,
                     before,
                     after,
                     openingTag,
                     closingTag);
    addRule(tag, rule);
}

void HtmlSed::resolveUrl(const QString& tagToResolve,
                         const QString& attributeToResolve,
                         const QString& baseUrl)
{
    Rule rule;
    rule.resolveUrl(tagToResolve,
                    attributeToResolve,
                    baseUrl);
    addRule(tagToResolve, rule);
}

void HtmlSed::modifyTag(const QString& tag,
                        Modifier* modifier)
{
    Rule rule;
    rule.modifyTag(tag,
                   modifier);
    addRule(tag, rule);
}

QString HtmlSed::toString() const
{
    QString html = myHtml;
    QString out;

    int offset = 0;
    int tagPosition = 0;

    Tag previousTag("");

    qDebug() << "Parsing" << html.size() << "bytes of HTML...";

    QList<Tag> tagStack;
    while (true)
    {
        // find the next tag, and the PCDATA up to that tag
        const QString tagData = findTag(html, offset, tagPosition);
        const QString pcData = html.mid(offset, tagData.isEmpty() ? -1 : tagPosition);
        offset += tagPosition + tagData.size();

        //qDebug() << "PCDATA" << pcData;
        //qDebug() << "DATA" << tagData;

        /*
        qDebug() << "Tag Stack:";
        foreach (const Tag& t, tagStack)
        {
            qDebug() << " -" << t.toString() << "hidden" << t.isHidden();
        }
        */

        bool isHidden = false;
        foreach (const Tag& t, tagStack)
        {
            if (t.isHidden())
            {
                isHidden = true;
                break;
            }
        }

        if (! isHidden)
        {
            out.append(pcData);
        }

        if (tagData.isEmpty())
        {
            break;
        }

        if (tagData.startsWith("<!"))
        {
            continue;
        }

        Tag tag(tagData);

        // try to detect and ignore false tags
        if (previousTag.name() == "SCRIPT" &&
            ! previousTag.isClosing() &&
            (tag.name() != "SCRIPT" || ! tag.isClosing()))
        {
            continue;
        }

        // apply the rules
        if (! isHidden && (myRuleSet.contains(tag.name()) || myRuleSet.contains(QString())))
        {
            QList<Rule> rules = myRuleSet.value(tag.name(),
                                                         QList<Rule>()) +
                                         myRuleSet.value(QString(),
                                                         QList<Rule>());

            foreach (const Rule& rule, rules)
            {
                if (rule.mode == Rule::REPLACE_CONTENTS)
                {
                    // replace contents
                    if (tag.isOpening())
                    {
                        tag.setHidden(true);
                        out.append(rule.replaceWith);
                    }
                }
                else if (rule.mode == Rule::RESOLVE_URL &&
                         tag.isOpening() &&
                         tag.hasAttribute(rule.attribute))
                {
                    // resolve URL
                    QString url = tag.attribute(rule.attribute);
                    if (url.startsWith("http://") ||
                        url.startsWith("https://") ||
                        url.startsWith("#"))
                    {
                        // do nothing
                    }
                    else
                    {
                        tag.setAttribute(rule.attribute,
                                         QUrl(rule.resolveBaseUrl)
                                         .resolved(url)
                                         .toString());
                    }
                }
                else if (rule.mode == Rule::REPLACE_ATTRIBUTE)
                {
                    // replace tag attribute
                    if (tag.hasAttribute(rule.attribute))
                    {
                        QString value = tag.attribute(rule.attribute);
                        tag.setAttribute(rule.attribute,
                                         rule.replaceWith);
                    }
                }
                else if (rule.mode == Rule::REPLACE_TAG)
                {
                    // replace tag
                    if ((rule.openingTag && tag.isOpening()) ||
                        (rule.closingTag && tag.isClosing()))
                    {
                        tag.replaceWith(rule.replaceWith);
                    }
                }
                else if (rule.mode == Rule::SURROUND_TAG)
                {
                    if ((rule.openingTag && tag.isOpening()) ||
                        (rule.closingTag && tag.isClosing()))
                    {
                        tag.setSurroundings(rule.replaceWith,
                                            rule.replaceWithAfter);
                    }
                }
                else if (rule.mode == Rule::MODIFY_TAG)
                {
                    rule.tagModifier->modifyTag(tag);
                }

                // if the tag is now hidden then exit
                if (tag.isHidden())
                {
                    isHidden = true;
                    break;
                }

            }//foreach rule

        }//if in rule set

        // maintain tag stack
        if (tag.isOpening())
        {
            tagStack << tag;
        }
        if (tag.isClosing())
        {
            while (tagStack.size())
            {
                Tag t = tagStack.takeLast();
                if (t.name() == tag.name())
                {
                    break;
                }
            }
        }

        if (! isHidden)
        {
            if (tag.isModified())
            {
                out.append(tag.toString());
            }
            else
            {
                out.append(tagData);
            }
        }

        previousTag = tag;

    }//while

    qDebug() << "Done parsing HTML.";

    return out;
}
