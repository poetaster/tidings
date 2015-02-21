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

}

HtmlFilter::HtmlFilter(QObject* parent)
    : QObject(parent)
    , myIsBusy(false)
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

    myIsBusy = true;
    emit busyChanged();

    QFuture<QPair<QString, QStringList> > filteredFuture =
            QtConcurrent::run(this,
                              &HtmlFilter::filter,
                              myHtml,
                              myBaseUrl,
                              myImageProxy);
    myFilteredFutureWatcher.setFuture(filteredFuture);
}

QPair<QString, QStringList> HtmlFilter::filter(QString html,
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
    htmlSed.dropTag("B");
    htmlSed.dropTag("I");
    htmlSed.dropTag("DIV");
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
    QString filtered = htmlSed.toString();
    QStringList images = imageModifier.images().toList();
    images.sort(Qt::CaseInsensitive);
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
}
