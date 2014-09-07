import QtQuick 2.0

Timer {
    property var bgWorkers: []

    function execute(worker)
    {
        bgWorkers.push(worker);

        if (! running)
        {
            start();
        }
    }

    function abort()
    {
        bgWorkers = [];
        stop();
    }

    interval: 150
    repeat: true

    onTriggered: {
        var begin = new Date();
        var now = begin;

        while (bgWorkers.length > 0 &&
               now.getTime() - begin.getTime() < 30 /*ms*/)
        {
            if (!bgWorkers[0]())
            {
                bgWorkers.shift();
                if (bgWorkers.length === 0)
                {
                    stop();
                }
                break;
            }
            now = new Date();
        }
    }
}
