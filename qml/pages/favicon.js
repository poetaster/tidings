.pragma library

/* Returns the host of a URL.
 */
function host(url) {
    var idx = url.search("://");
    var s = url.substring(idx + 3);
    var idx2 = s.search("/");
    return url.substring(0, idx + idx2 + 3);
}

/* Returns the URL of a fav icon in the given HTML data, or an empty string if
 * none was found.
 */
function favIcon(data) {
    var idx = data.search(/<link .*rel *=.*shortcut icon/i);
    if (idx === -1) {
        return "";
    }

    var s = data.substring(idx);
    var idx2 = s.search(">");
    s = s.substring(0, idx2);

    idx = s.search("href");
    s = s.substring(idx + 4);
    idx = s.search(/[^= "']/);
    s = s.substring(idx);
    idx = s.search(/[ "']/);

    console.log(s.substring(0, idx));
    return s.substring(0, idx);

    /* <link href="/templates/klack/favicon.ico" rel="shortcut icon" type="image/x-icon" /> */
}
