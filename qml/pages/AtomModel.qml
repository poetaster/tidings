/* Copyright (C) 2013 - 2017 Martin Grimme  <martin.grimme _AT_ gmail.com>
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
    query: "/atom:feed/atom:entry"
    namespaceDeclarations: "declare namespace atom = 'http://www.w3.org/2005/Atom';"

    XmlRole { name: "uid"; query: "atom:id/string()" }
    XmlRole { name: "title"; query: "atom:title/string()" }
    XmlRole { name: "link"; query: "atom:link/@href/string()" }

    XmlRole { name: "linksAmount"; query: "count(atom:link/@href/string())" }
    XmlRole { name: "link_1_href"; query: "atom:link[1]/@href/string()" }
    XmlRole { name: "link_1_rel"; query: "atom:link[1]/@rel/string()" }
    XmlRole { name: "link_1_type"; query: "atom:link[1]/@type/string()" }
    XmlRole { name: "link_2_href"; query: "atom:link[2]/@href/string()" }
    XmlRole { name: "link_2_rel"; query: "atom:link[2]/@rel/string()" }
    XmlRole { name: "link_2_type"; query: "atom:link[2]/@type/string()" }
    XmlRole { name: "link_3_href"; query: "atom:link[3]/@href/string()" }
    XmlRole { name: "link_3_rel"; query: "atom:link[3]/@rel/string()" }
    XmlRole { name: "link_3_type"; query: "atom:link[3]/@type/string()" }
    XmlRole { name: "link_4_href"; query: "atom:link[4]/@href/string()" }
    XmlRole { name: "link_4_rel"; query: "atom:link[4]/@rel/string()" }
    XmlRole { name: "link_4_type"; query: "atom:link[4]/@type/string()" }
    XmlRole { name: "link_5_href"; query: "atom:link[5]/@href/string()" }
    XmlRole { name: "link_5_rel"; query: "atom:link[5]/@rel/string()" }
    XmlRole { name: "link_5_type"; query: "atom:link[5]/@type/string()" }

    XmlRole { name: "description"; query: "atom:summary/string()" }
    XmlRole { name: "encoded"; query: "atom:content/string()" }
    XmlRole { name: "dateString"; query: "atom:updated/string()" }
}
