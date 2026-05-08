const localhostExp = /(http|https):\/\/(localhost|127\.0\.0\.1).*/;
const statusOk = /.*200 OK.*/g;
const hostName = "com.snowsoftware.cloudmetering";
const sendIntervalInSeconds = 5;
const nativeHostIdleTime = 60;

var port = null;
var lastSend = new Date();
var gatheredData = {}

StartTimer();

function onDisconnected() {
    console.log( chrome.runtime.lastError.message);
    port = null;
}

function connectNativeHost() {
    if (port) {
        var now = new Date();
        var seconds = (now - lastSend) / 1000;
        if(seconds > nativeHostIdleTime)
        {
            console.log("Closing native host connection");
            port.disconnect();
            port = null;
        }
    }

    if(!port) {
        console.log("Opening native host connection");
        lastSend = new Date();
        port = chrome.runtime.connectNative(hostName);
        port.onDisconnect.addListener(onDisconnected);
    }
}

chrome.webRequest.onCompleted.addListener(
    function(details)
    {
        if( !details.fromCache && IsWantedStatusCode( details.statusCode ) ) {
            // Filter calls to localhost
            var result = localhostExp.exec( details.url );
            if( result == null ) {
				StoreURL( details.url, "" );
            }
        }
        return { cancel: false };
    },
    {
        urls: ["*://*/*"]
    },
    []
);

function StartTimer()
{
    // We don't want to start a new send before the previous send has completed
    // so we use setTimeout instead of setInterval.
    setTimeout(SendWaitingData, sendIntervalInSeconds * 1000);

    // Trying to connect some time before SendWaitingData is called, allows time for the native host's onDisconnected to be called.
    connectNativeHost();
}

function SendToAgent( data, numberOfURLs )
{
    if (port) {
        console.log("Sending message to native host...");
        lastSend = new Date();
        port.postMessage(data);
    }
}

function SendWaitingData()
{
    let count = Object.keys( gatheredData ).length;
    if( count > 0 ) {
        console.log("Sending " + count + " URLs.");

        let dataToSend = {
            "source-browser" : "Chrome",
            "url" : gatheredData
        };

        SendToAgent(dataToSend, count);
        gatheredData = {};
    }
    else {
        console.log("Nothing to send");
    }
	StartTimer();
}

function StoreURL( url, tabTitle )
{
    gatheredData[url] = {
        // Empty object for now
    }
}

function IsWantedStatusCode( code )
{
    return code >= 200 && code < 300;
}
