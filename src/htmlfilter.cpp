#include "htmlfilter.h"
#include "htmlsed.h"

#include <QFuture>
#include <QtConcurrent>
#include <QDebug>

namespace
{

const QRegExp RE_STYLE_COLOR("color:\\s*[^\\s;\"']+;?");
const QRegExp RE_STYLE_FONT_SIZE("font-size:\\s*\\d+[a-zA-Z]*;?");
const QRegExp RE_STYLE_DISPLAY_NONE("display:\\s*none;?");
const QRegExp NO_DIGIT("[^\\d]");

class GenericModifier : public HtmlSed::Modifier
{
public:
    virtual void modifyTag(HtmlSed::Tag& tag)
    {
        tag.removeAttribute("CLASS");

        if (tag.hasAttribute("STYLE"))
        {
            if (tag.attribute("STYLE").contains(RE_STYLE_DISPLAY_NONE))
            {
                tag.setHidden(true);
            }
            else
            {
                QString style = tag.attribute("STYLE");
                style.replace(RE_STYLE_COLOR, QString())
                     .replace(RE_STYLE_FONT_SIZE, QString());
                tag.setAttribute("STYLE", style);
            }
        }

        if (tag.name() == "A" && tag.isOpening() &&
                (! tag.hasAttribute("HREF") || tag.attribute("HREF").startsWith("#")))
        {
            tag.setHidden(true);
        }
    }
};

class VideoModifier : public HtmlSed::Modifier
{
public:
    virtual void modifyTag(HtmlSed::Tag& tag)
    {
        tag.setName("IMG");
        const QString src = tag.attribute("SRC");
        tag.setSurroundings("<A HREF=\"" + src + "\">",
                            "</A>");
        tag.setAttribute("SRC", tag.attribute("POSTER"));
    }
};

class ImageModifier : public HtmlSed::Modifier
{
public:
    ImageModifier(const QString& imagePlaceholder)
        : myPlaceholder(imagePlaceholder)
    { }
    virtual void modifyTag(HtmlSed::Tag& tag)
    {
        // fix invalid width / height that can crash QML Text
        if (tag.hasAttribute("WIDTH"))
        {
            tag.setAttribute("WIDTH",
                             tag.attribute("WIDTH")
                                .replace(NO_DIGIT, ""));
        }
        if (tag.hasAttribute("HEIGHT"))
        {
            tag.setAttribute("HEIGHT",
                             tag.attribute("HEIGHT")
                                .replace(NO_DIGIT, ""));
        }

        if (tag.attribute("WIDTH") == "0" || tag.attribute("HEIGHT") == "0" ||
            tag.attribute("WIDTH") == "1" || tag.attribute("HEIGHT") == "1")
        {
            // remove those damn tracking pixels...
            tag.replaceWith("");
        }
        else
        {
            myImages << tag.attribute("SRC");
            if (myPlaceholder.size())
            {
                tag.setAttribute("SRC", myPlaceholder);
            }
        }
    }

    QSet<QString> images() const
    {
        return myImages;
    }

private:
    QString myPlaceholder;
    QSet<QString> myImages;
};

class IFrameModifier : public HtmlSed::Modifier
{
public:
    virtual void modifyTag(HtmlSed::Tag& tag)
    {
        if (tag.hasAttribute("SRC"))
        {
            const QString src = tag.attribute("SRC");
            if (src.startsWith("http://www.youtube.") ||
                    src.startsWith("https://www.youtube."))
            {
                // this is probably an embedded YouTube video
                tag.replaceWith(
                            QString("<P><A HREF=\"%1\">[YouTube Video]</A></P>")
                            .arg(src));
            }
            else
            {
                tag.replaceWith("");
            }
        }
        else
        {
            tag.replaceWith("");
        }
    }
};

}

HtmlFilter::HtmlFilter(QObject* parent)
    : QObject(parent)
    , myIsBusy(false)
    , myProcessingRequested(false)
{
    connect(&myFilteredFutureWatcher, SIGNAL(finished()),
            this, SLOT(slotFilteredFinished()));
}

void HtmlFilter::setBaseUrl(const QString& baseUrl)
{
    myBaseUrl = baseUrl;
    emit baseUrlChanged();
    process();
}

void HtmlFilter::setImageProxy(const QString& imageProxy)
{
    myImageProxy = imageProxy;
    emit imageProxyChanged();
    process();
}

void HtmlFilter::setHtml(const QString& html)
{
    myHtml = html;
    emit htmlChanged();

    process();
}

void HtmlFilter::process()
{
    if (myHtml.isEmpty())
    {
        return;
    }

    if (myIsBusy)
    {
        myProcessingRequested = true;
        return;
    }
    else
    {
        myProcessingRequested = false;
    }

    myIsBusy = true;
    emit busyChanged();

    QFuture<QPair<QString, QStringList> > filteredFuture =
            QtConcurrent::run(this,
                              &HtmlFilter::filter,
                              // make explicit copies
                              QString::fromUtf16(myHtml.utf16()),
                              QString::fromUtf16(myBaseUrl.utf16()),
                              QString::fromUtf16(myImageProxy.utf16()));
    myFilteredFutureWatcher.setFuture(filteredFuture);
}

QPair<QString, QStringList> HtmlFilter::filter(const QString& html,
                                               const QString& url,
                                               const QString& imagePlaceHolder) const
{
    GenericModifier genericModifier;
    IFrameModifier iframeModifier;
    ImageModifier imageModifier(imagePlaceHolder);
    VideoModifier videoModifier;

    //qDebug() << "BEFORE" << html;
    HtmlSed htmlSed(html);
    htmlSed.dropTag("HTML");
    htmlSed.dropTag("BODY");
    htmlSed.dropTagWithContents("SCRIPT");
    htmlSed.dropTagWithContents("STYLE");
    htmlSed.dropTagWithContents("HEAD");
    htmlSed.dropTag("LINK"); // why does this tag exist outside HEAD (tweakers.nl)
    htmlSed.dropTag("FONT");
    htmlSed.dropTagWithContents("FORM");
    htmlSed.dropTagWithContents("NAV");
    htmlSed.dropTag("HEADER");
    htmlSed.dropTagWithContents("FOOTER");
    htmlSed.dropTag("INPUT");
    htmlSed.dropTag("ARTICLE");
    htmlSed.dropTag("ASIDE");
    htmlSed.replaceTag("DIV", "<P>", true, false);
    htmlSed.replaceTag("DIV", "</P>", false, true);
    htmlSed.replaceTag("TABLE", "<P>", true, false);
    htmlSed.replaceTag("TABLE", "</P>", false, true);
    htmlSed.dropTag("THEAD");
    htmlSed.dropTag("TBODY");
    htmlSed.replaceTag("TR", "<BLOCKQUOTE>", true, false);
    htmlSed.replaceTag("TR", "</BLOCKQUOTE>", false, true);
    htmlSed.replaceTag("TD", "<BR>");
    htmlSed.replaceTag("A", "</A> ", false, true);
    htmlSed.surroundTag("LI", "", "&nbsp;", true, false);
    htmlSed.resolveUrl("A", "HREF", url);
    htmlSed.resolveUrl("IMG", "SRC", url);

    htmlSed.modifyTag("", &genericModifier);
    htmlSed.modifyTag("IFRAME", &iframeModifier);
    htmlSed.modifyTag("IMG", &imageModifier);
    htmlSed.modifyTag("VIDEO", &videoModifier);

    QString filtered = htmlSed.toString().trimmed();

    if (filtered.size() > 1024 * 100)
    {
        qDebug() << "Article exceeds 100k after sanitizing. Cropping off.";
        filtered = filtered.left(1024 * 100);
    }

    QStringList images = imageModifier.images().toList();
    images.sort(Qt::CaseInsensitive);
    //qDebug() << "AFTER" << filtered;
    return QPair<QString, QStringList>(filtered, images);
}

void HtmlFilter::slotFilteredFinished()
{
    QPair<QString, QStringList> data =
            myFilteredFutureWatcher.future().result();
    myHtmlFiltered = data.first;
    myImages = data.second;
    emit filtered();
    emit imagesChanged();

    myIsBusy = false;
    emit busyChanged();

    if (myProcessingRequested)
    {
        process();
    }
}
