/* Copyright (C) 2013, 2014 Martin Grimme  <martin.grimme _AT_ gmail.com>
 *
 * This file was apapted from WeRSS
 * Copyright (C) 2010, 2011 Martin Grimme  <martin.grimme _AT_ gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

import QtQuick 2.0
import QtQuick.XmlListModel 2.0

XmlListModel {
    query: "/rss/channel/item"
    namespaceDeclarations: "declare namespace media = 'http://search.yahoo.com/mrss/';" +
            "declare namespace content = 'http://purl.org/rss/1.0/modules/content/';" +
            "declare namespace itunes = 'http://www.itunes.com/DTDs/Podcast-1.0.dtd';"

    XmlRole { name: "uid"; query: "normalize-space(guid/string())" }
    XmlRole { name: "title"; query: "normalize-space(title/string())" }
    XmlRole { name: "link"; query: "normalize-space(link/string())" }
    XmlRole { name: "description"; query: "description/string()" }
    XmlRole { name: "encoded"; query: "normalize-space(content:encoded/string())" }
    XmlRole { name: "dateString"; query: "normalize-space(pubDate/string())" }

    XmlRole { name: "duration"; query: "media:content/@duration/string()" }

    XmlRole { name: "iTunesImage"; query: "itunes:image/@href/string()" }

    XmlRole { name: "thumbnailsAmount"; query: "count(media:thumbnail[1]/@url/string())" }
    XmlRole { name: "thumbnail_1_url";   query: "media:thumbnail[1]/@url/string()" }
    XmlRole { name: "thumbnail_1_width"; query: "media:thumbnail[1]/@width/string()" }
    XmlRole { name: "thumbnail_2_url";   query: "media:thumbnail[2]/@url/string()" }
    XmlRole { name: "thumbnail_2_width"; query: "media:thumbnail[2]/@width/string()" }
    XmlRole { name: "thumbnail_3_url";   query: "media:thumbnail[3]/@url/string()" }
    XmlRole { name: "thumbnail_3_width"; query: "media:thumbnail[3]/@width/string()" }
    XmlRole { name: "thumbnail_4_url";   query: "media:thumbnail[4]/@url/string()" }
    XmlRole { name: "thumbnail_4_width"; query: "media:thumbnail[4]/@width/string()" }
    XmlRole { name: "thumbnail_5_url";   query: "media:thumbnail[5]/@url/string()" }
    XmlRole { name: "thumbnail_5_width"; query: "media:thumbnail[5]/@width/string()" }
    XmlRole { name: "thumbnail_6_url";   query: "media:thumbnail[6]/@url/string()" }
    XmlRole { name: "thumbnail_6_width"; query: "media:thumbnail[6]/@width/string()" }
    XmlRole { name: "thumbnail_7_url";   query: "media:thumbnail[7]/@url/string()" }
    XmlRole { name: "thumbnail_7_width"; query: "media:thumbnail[7]/@width/string()" }
    XmlRole { name: "thumbnail_8_url";   query: "media:thumbnail[8]/@url/string()" }
    XmlRole { name: "thumbnail_8_width"; query: "media:thumbnail[8]/@width/string()" }
    XmlRole { name: "thumbnail_9_url";   query: "media:thumbnail[9]/@url/string()" }
    XmlRole { name: "thumbnail_9_width"; query: "media:thumbnail[9]/@width/string()" }

    XmlRole { name: "enclosuresAmount"; query: "count(enclosure[1]/@url/string())" }
    XmlRole { name: "enclosure_1_url";      query: "enclosure[1]/@url/string()" }
    XmlRole { name: "enclosure_1_type";     query: "enclosure[1]/@type/string()" }
    XmlRole { name: "enclosure_1_length";   query: "enclosure[1]/@length/string()" }
    XmlRole { name: "enclosure_2_url";      query: "enclosure[2]/@url/string()" }
    XmlRole { name: "enclosure_2_type";     query: "enclosure[2]/@type/string()" }
    XmlRole { name: "enclosure_2_length";   query: "enclosure[2]/@length/string()" }
    XmlRole { name: "enclosure_3_url";      query: "enclosure[3]/@url/string()" }
    XmlRole { name: "enclosure_3_type";     query: "enclosure[3]/@type/string()" }
    XmlRole { name: "enclosure_3_length";   query: "enclosure[3]/@length/string()" }
    XmlRole { name: "enclosure_4_url";      query: "enclosure[4]/@url/string()" }
    XmlRole { name: "enclosure_4_type";     query: "enclosure[4]/@type/string()" }
    XmlRole { name: "enclosure_4_length";   query: "enclosure[4]/@length/string()" }
    XmlRole { name: "enclosure_5_url";      query: "enclosure[5]/@url/string()" }
    XmlRole { name: "enclosure_5_type";     query: "enclosure[5]/@type/string()" }
    XmlRole { name: "enclosure_5_length";   query: "enclosure[5]/@length/string()" }
    XmlRole { name: "enclosure_6_url";      query: "enclosure[6]/@url/string()" }
    XmlRole { name: "enclosure_6_type";     query: "enclosure[6]/@type/string()" }
    XmlRole { name: "enclosure_6_length";   query: "enclosure[6]/@length/string()" }
    XmlRole { name: "enclosure_7_url";      query: "enclosure[7]/@url/string()" }
    XmlRole { name: "enclosure_7_type";     query: "enclosure[7]/@type/string()" }
    XmlRole { name: "enclosure_7_length";   query: "enclosure[7]/@length/string()" }
    XmlRole { name: "enclosure_8_url";      query: "enclosure[8]/@url/string()" }
    XmlRole { name: "enclosure_8_type";     query: "enclosure[8]/@type/string()" }
    XmlRole { name: "enclosure_8_length";   query: "enclosure[8]/@length/string()" }
    XmlRole { name: "enclosure_9_url";      query: "enclosure[9]/@url/string()" }
    XmlRole { name: "enclosure_9_type";     query: "enclosure[9]/@type/string()" }
    XmlRole { name: "enclosure_9_length";   query: "enclosure[9]/@length/string()" }
}
