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
    query: "/rdf:RDF/item"
    namespaceDeclarations: "declare default element namespace 'http://purl.org/rss/1.0/';" +
                           "declare namespace rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';" +
                           "declare namespace dc = 'http://purl.org/dc/elements/1.1/';" +
                           "declare namespace content = 'http://purl.org/rss/1.0/modules/content/';"

    XmlRole { name: "uid"; query: "guid/string()" }
    XmlRole { name: "title"; query: "title/string()" }
    XmlRole { name: "link"; query: "link/string()" }
    XmlRole { name: "description"; query: "description/string()" }
    XmlRole { name: "encoded"; query: "content:encoded/string()" }
    XmlRole { name: "dateString"; query: "dc:date/string()" }
}
