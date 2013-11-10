/* Copyright (C) 2013 Martin Grimme  <martin.grimme _AT_ gmail.com>
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
    property string name

    query: "/opml/body/outline"

    XmlRole { name: "title"; query: "@title/string()" }
    XmlRole { name: "link"; query: "@xmlUrl/string()" }
    XmlRole { name: "dateString"; query: "" } // doesn't exist
    XmlRole { name: "description"; query: "@text/string()" }
    XmlRole { name: "thumbnail"; query: "" } // doesn't exist
}
