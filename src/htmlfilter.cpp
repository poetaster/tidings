#include "htmlfilter.h"
#include "htmlsed.h"

#include <QFuture>
#include <QtConcurrent>
#include <QDebug>

namespace
{

const QString RE_STYLE_COLOR("color:\\s*[^\\s;\"']+;?");
const QString RE_STYLE_FONT_SIZE("font-size:\\s*\\d+[a-zA-Z]*;?");

class VideoModifier : public HtmlSed::Modifier
{
public:
    void modifyTag(HtmlSed::Tag& tag)
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
    void modifyTag(HtmlSed::Tag& tag)
    {
        if (tag.attribute("WIDTH") == "1" || tag.attribute("HEIGHT") == "1")
        {
            // remove those damn tracking pixels...
            tag.replaceWith("");
        }
        else if (myPlaceholder.size())
        {
            tag.setAttribute("SRC", myPlaceholder);
        }
    }
private:
    QString myPlaceholder;
};

class ImageCollector : public HtmlSed::Modifier
{
public:
    void modifyTag(HtmlSed::Tag& tag)
    {
        if (tag.attribute("WIDTH") == "1" || tag.attribute("HEIGHT") == "1")
        {
            // don't collect those damn tracking pixels...
        }
        else if (tag.hasAttribute("SRC"))
        {
            myImages << tag.attribute("SRC");
        }
    }

    QSet<QString> images() const
    {
        return myImages;
    }

private:
    QSet<QString> myImages;
};

}

HtmlFilter::HtmlFilter(QObject* parent)
    : QObject(parent)
    , myIsBusy(false)
{
    connect(&myFilteredFutureWatcher, SIGNAL(finished()),
            this, SLOT(slotFilteredFinished()));
    connect(&myImagesFutureWatcher, SIGNAL(finished()),
            this, SLOT(slotImagesFinished()));
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

    QFuture<QStringList> imagesFuture = QtConcurrent::run(this,
                                                          &HtmlFilter::getImages,
                                                          myHtml);
    myImagesFutureWatcher.setFuture(imagesFuture);

    process();
}

void HtmlFilter::process()
{
    if (myHtml.isEmpty())
    {
        return;
    }

    myIsBusy = true;
    emit busyChanged();

    QFuture<QString> filteredFuture = QtConcurrent::run(this,
                                                        &HtmlFilter::filter,
                                                        myHtml,
                                                        myBaseUrl,
                                                        myImageProxy);
    myFilteredFutureWatcher.setFuture(filteredFuture);
}

QString HtmlFilter::filter(QString html,
                           QString url,
                           QString imagePlaceHolder) const
{
    VideoModifier videoModifier;
    ImageModifier imageModifier(imagePlaceHolder);

    qDebug() << "BEFORE" << html;
    HtmlSed htmlSed(html);
    htmlSed.dropTag("HTML");
    htmlSed.dropTag("BODY");
    htmlSed.dropTagWithContents("SCRIPT");
    htmlSed.dropTagWithContents("NOSCRIPT");
    htmlSed.dropTagWithContents("HEAD");
    htmlSed.dropTag("FONT");
    htmlSed.dropTag("LINK");
    htmlSed.dropTagWithContents("FORM");
    htmlSed.dropTagWithContents("NAV");
    htmlSed.dropTag("HEADER");
    htmlSed.dropTagWithContents("FOOTER");
    htmlSed.dropTag("INPUT");
    htmlSed.dropTag("ASIDE");
    htmlSed.replaceTag("TABLE", "<P>", true, false);
    htmlSed.replaceTag("TABLE", "</P>", false, true);
    htmlSed.dropTag("THEAD");
    htmlSed.dropTag("TBODY");
    htmlSed.replaceTag("TR", "<BLOCKQUOTE>", true, false);
    htmlSed.replaceTag("TR", "</BLOCKQUOTE>", false, true);
    htmlSed.replaceTag("TD", "<BR>");
    htmlSed.surroundTag("LI", "", "&nbsp;", true, false);
    htmlSed.replaceAttribute("", "STYLE", RE_STYLE_COLOR, "");
    htmlSed.replaceAttribute("", "STYLE", RE_STYLE_FONT_SIZE, "");
    htmlSed.resolveUrl("A", "HREF", url);
    //htmlSed.resolveUrl("IMG", "SRC", url);
    htmlSed.modifyTag("IMG", &imageModifier);
    htmlSed.modifyTag("VIDEO", &videoModifier);

    //qDebug() << "AFTER" << htmlSed.toString();
    return htmlSed.toString();
}

QStringList HtmlFilter::getImages(const QString& html) const
{
    ImageCollector collector;

    HtmlSed htmlSed(html);
    htmlSed.modifyTag("IMG", &collector);
    htmlSed.toString();
    return collector.images().toList();
}

void HtmlFilter::slotFilteredFinished()
{
    myHtmlFiltered = myFilteredFutureWatcher.future().result();
    emit filtered();

    myIsBusy = false;
    emit busyChanged();
}

void HtmlFilter::slotImagesFinished()
{
    myImages = myImagesFutureWatcher.future().result();
    emit imagesChanged();
}
