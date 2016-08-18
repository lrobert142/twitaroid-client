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

    property string shuffleButtonText: "SHUFFLE"
    property string shuffleButtonLoadingText: "Loading..."
    property string polaroidInitUrl: "http://localhost:8080/init"
    property string webSocketUrl: "ws://localhost:8080/chat"

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
                    shuffleText.text = shuffleButtonText;
                } else {
                    console.log("Error: " + http.status + " " + http.statusText);
                    console.log("Response: " + http.responseText);
                }
            }
        }

        http.send();
    }

    Component.onCompleted: {
        fetchPolaroidData();
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
        id: shuffleButton
        height: 40
        width: shuffleText.width + 20
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
            id: shuffleText
            width: 80
            anchors.fill: shuffleButton
            text: shuffleButtonLoadingText
            anchors.margins: 10
            z: 10001

            color: "white"
            font.bold: true
        }

        MouseArea {
            id: resetArea
            anchors.fill: shuffleButton
            onClicked: {
                if(shuffleText.text === shuffleButtonText) {
                    shuffleText.text = shuffleButtonLoadingText
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
            right: shuffleButton.left
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
