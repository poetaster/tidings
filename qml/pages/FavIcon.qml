import QtQuick 2.0
import "favicon.js" as FavIcon

/* Takes the URL of a website and tries to retrieve its favicon.
 */
Image {

    property string site

    function onResponse(xhr) {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            source = FavIcon.host(site) + FavIcon.favIcon(xhr.responseText);
        }
    }

    onSiteChanged: {
        var closure = function(xhr) {
            return function() {
                onResponse(xhr);
            }
        };

        console.log("host: " + FavIcon.host(site));

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = closure(xhr);
        xhr.open("GET", FavIcon.host(site), true);
        xhr.send();
    }


}
