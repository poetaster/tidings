var debug = true

WorkerScript.onMessage = function(message) {
    console.log(message.model.count)
    var xmlModel = message.model
    var sourcesModel = message.sources
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
    WorkerScript.sendMessage({ 'reply': 'Done'})
}

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
