import QtQuick 2.5
import QtQuick.Window 2.1
import QtWebSockets 1.0

Window {
    id: root
    visible: true
    width: 1024; height: 600
    color: "black"
    property int highestZ: 0
    property real defaultSize: 200
    property var currentFrame: undefined
    property real surfaceViewportRatio: 1.5
    property bool filtered: true

    property string resetButtonText: "SHUFFLE"
    property string resetButtonLoadingText: "Loading..."
    property string addressRequestUrl: "http://axrs.io/_services/twitaroid.json"
    property string polaroidInitUrl: ""
    property string webSocketUrl: ""

    function init(callback) {
        var http = new XMLHttpRequest();
        var url = addressRequestUrl;
        http.open("GET", url, true);
        http.onreadystatechange = function() {
            if(http.readyState == 4) {
                if(http.status == 200) {
                    var responseJson = JSON.parse(http.responseText);
                    polaroidInitUrl = "http://" + responseJson.ip + "/init";
                    webSocketUrl = "ws://" + responseJson.socket + "/chat";
                    callback();
                } else {
                    console.log("Error: " + http.status + " " + http.statusText);
                    console.log("Response: " + http.responseText);
                }
            }
        }

        http.send();
    }

    function fetchPolaroidData() {
        var http = new XMLHttpRequest();
        var url = polaroidInitUrl;
        http.open("GET", url, true);
        http.onreadystatechange = function() {
            if(http.readyState == 4) {
                if(http.status == 200) {
                    var responseJsonArray = JSON.parse(http.responseText);
                    responseJsonArray.forEach(function(entry) {
                        tweets.append(entry);
                    });
                    resetText.text = resetButtonText;
                } else {
                    console.log("Error: " + http.status + " " + http.statusText);
                    console.log("Response: " + http.responseText);
                }
            }
        }

        http.send();
    }

    Component.onCompleted: {
        init(fetchPolaroidData);
    }

    WebSocket {
        id: socket
        url: webSocketUrl
        active: true

        onTextMessageReceived: {
            if(message.substring(0, 1) === "0") {
                var json = JSON.parse(message.substring(1, message.length));
                tweets.append(json);
            }
        }
    }
    ListModel{
        id:tweets;
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width * surfaceViewportRatio
        contentHeight: height * surfaceViewportRatio

        Repeater {
            id: repeater
            model: tweets

            Polaroid {
                id: polaroid
            }
        }
    }

    Rectangle {
        id: verticalScrollDecorator
        anchors.right: parent.right
        anchors.margins: 2
        color: "cyan"
        border.color: "black"
        border.width: 1
        width: 5
        radius: 2
        antialiasing: true
        height: flick.height * (flick.height / flick.contentHeight) - (width - anchors.margins) * 2
        y:  flick.contentY * (flick.height / flick.contentHeight)
        NumberAnimation on opacity { id: vfade; to: 0; duration: 500 }
        onYChanged: { opacity = 1.0; fadeTimer.restart() }
    }

    Rectangle {
        id: horizontalScrollDecorator
        anchors.bottom: parent.bottom
        anchors.margins: 2
        color: "cyan"
        border.color: "black"
        border.width: 1
        height: 5
        radius: 2
        antialiasing: true
        width: flick.width * (flick.width / flick.contentWidth) - (height - anchors.margins) * 2
        x:  flick.contentX * (flick.width / flick.contentWidth)
        NumberAnimation on opacity { id: hfade; to: 0; duration: 500 }
        onXChanged: { opacity = 1.0; fadeTimer.restart() }
    }

    Timer { id: fadeTimer; interval: 1000; onTriggered: { hfade.start(); vfade.start() } }

    Text {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        color: "darkgrey"
        wrapMode: Text.WordWrap
        font.pointSize: 8
        text: "On a touchscreen: use two fingers to zoom and rotate, one finger to drag\n" +
              "With a mouse: drag normally, use the vertical wheel to zoom, horizontal wheel to rotate, or hold Ctrl while using the vertical wheel to rotate"
    }

    Rectangle {
        id: resetButton
        height: 40
        width: resetText.width + 20
        anchors {
            right: parent.right
            top: parent.top
            margins: 10
        }

        z: 10000
        radius: 10

        color: "#787C82"
        border.color: "#54575C"
        border.width: 2

        Text {
            id: resetText
            width: 80
            anchors.fill: resetButton
            text: resetButtonLoadingText
            anchors.margins: 10
            z: 10001

            color: "white"
            font.bold: true
        }

        MouseArea {
            id: resetArea
            anchors.fill: resetButton
            onClicked: {
                if(resetText.text === resetButtonText) {
                    resetText.text = resetButtonLoadingText
                    tweets.clear();
                    fetchPolaroidData();
                }
            }
        }
    }

    Rectangle {
        id: imagesCountContainer
        height: 20
        width: imagesCount.width
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 10
        }

        color: "black"

        Text {
            id: imagesCount
            text: tweets.count + " images available!"
            color: "white"
        }
    }

    Rectangle {
        id: retweetFilterButton
        height: 40
        width: retweetFilterText.width + 20
        anchors {
            right: resetButton.left
            top: parent.top
            margins: 10
        }

        z: 10000
        radius: 10

        color: "#787C82"
        border.color: "#54575C"
        border.width: 2

        Text {
            id: retweetFilterText
            width: 120
            anchors.fill: retweetFilterButton
            text: (root.filtered)? "Show Retweets" : "Hide Retweets"
            anchors.margins: 10
            z: 10001

            color: "white"
            font.bold: true
        }

        MouseArea {
            id: retweetFilterArea
            anchors.fill: retweetFilterButton
            onClicked: {
                root.filtered = !(root.filtered);
            }
        }
    }
}
