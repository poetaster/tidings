var debug = true

function addSource(name, url, color) {
    url = url.trim();
    var sourceId = database.addSource(name, url, color);
    append({
               "sourceId": sourceId,
               "name": name,
               "url": url,
               "color": color
           });
    names[url] = name;
    colors[url] = color;

}
WorkerScript.onMessage = function(msg) {

    if (debug) console.log("Action > " + msg.action)

    msg.params = msg.params || []
    if (msg.action === "execute" && msg.params[0]) {
        // we recieve a function to execute as param 0
        msg.params[0].shift();
    }
    WorkerScript.sendMessage({ 'reply': 'Done'})

    /*
    console.log(msg.model.count)
    var xmlModel = msg.model
    var sourcesModel = msg.sources
    for( var x=0; x < xmlModel.count; x++ ) {
        if (debug) console.log(xmlModel.get(x).title)
        if (debug) console.log(xmlModel.get(x).xmlUrl)
        var name = xmlModel.get(x).title
        if (name === "") {
            name = xmlModel.get(x).text
        }
        var url = xmlModel.get(x).xmlUrl
        var color = '#'+Math.floor(Math.random()*16777215).toString(16)
        //sourcesModel.addSource(name,url,color)
        //sourcesModel.append({"name":name,"url":url, "color":color})
        WorkerScript.sendMessage({ 'add': {"name":name,"url":url, "color":color}})
    }
*/
    WorkerScript.sendMessage({ 'reply': 'Done'})
}
