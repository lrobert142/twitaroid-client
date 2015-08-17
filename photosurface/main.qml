/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
import QtQuick 2.5
import QtQuick.Dialogs 1.0
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

    Component.onCompleted: {
        var http = new XMLHttpRequest();
        var url = "http://127.0.0.1:8080/init";
        http.open("GET", url, true);
        http.onreadystatechange = function() {
            if(http.readyState == 4) {
                if(http.status == 200) {
                    var responseJsonArray = JSON.parse(http.responseText);
                    responseJsonArray.forEach(function(entry) {
                        imagesModel.append(entry);
                    });
                } else {
                    console.log("Error: " + http.status + " " + http.statusText);
                    console.log("Response: " + http.responseText);
                }
            }
        }

        http.send();
    }

    WebSocket {
        id: socket
        url: "ws://127.0.0.1:8081/chat"
        active: true

        onTextMessageReceived: {
            console.log(message);
            if(message.substring(0, 1) === "0") {
                var json = JSON.parse(message.substring(1, message.length));
                imagesModel.append(json);
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width * surfaceViewportRatio
        contentHeight: height * surfaceViewportRatio
        Repeater {
            model: ListModel {
                id: imagesModel
            }
            Rectangle {
                id: photoFrame
                width: image.width * (1 + 0.10 * image.height / image.width)
                height: image.height * 1.2
                scale: defaultSize / Math.max(image.sourceSize.width, image.sourceSize.height)
                Behavior on scale { NumberAnimation { duration: 200 } }
                Behavior on x { NumberAnimation { duration: 200 } }
                Behavior on y { NumberAnimation { duration: 200 } }
                border.color: "black"
                border.width: 2
                smooth: true
                antialiasing: true
                Component.onCompleted: {
                    x = Math.random() * root.width - width / 2
                    y = Math.random() * root.height - height / 2
                    rotation = Math.random() * 13 - 6
                }
                Image {
                    id: image
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    source: model.image_url
                    antialiasing: true
                }
                Text {
                    id: tweetText
                    text: {
                        var delimiter = "#twitaroid_dev";
                        var bodyText = model.body;
                        var endIndex = bodyText.lastIndexOf(delimiter) + delimiter.length;
                        bodyText.substring(0, endIndex);
                    }
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        bottomMargin: 5
                        leftMargin: 10
                    }
                    font.pointSize: 10
                    wrapMode: Text.WordWrap
                }

                PinchArea {
                    anchors.fill: parent
                    pinch.target: photoFrame
                    pinch.minimumRotation: -360
                    pinch.maximumRotation: 360
                    pinch.minimumScale: 0.1
                    pinch.maximumScale: 10
                    pinch.dragAxis: Pinch.XAndYAxis
                    onPinchStarted: setFrameColor();
                    property real zRestore: 0
                    onSmartZoom: {
                        if (pinch.scale > 0) {
                            photoFrame.rotation = 0;
                            photoFrame.scale = Math.min(root.width, root.height) / Math.max(image.sourceSize.width, image.sourceSize.height) * 0.85
                            photoFrame.x = flick.contentX + (flick.width - photoFrame.width) / 2
                            photoFrame.y = flick.contentY + (flick.height - photoFrame.height) / 2
                            zRestore = photoFrame.z
                            photoFrame.z = ++root.highestZ;
                        } else {
                            photoFrame.rotation = pinch.previousAngle
                            photoFrame.scale = pinch.previousScale
                            photoFrame.x = pinch.previousCenter.x - photoFrame.width / 2
                            photoFrame.y = pinch.previousCenter.y - photoFrame.height / 2
                            photoFrame.z = zRestore
                            --root.highestZ
                        }
                    }

                    MouseArea {
                        id: dragArea
                        hoverEnabled: true
                        anchors.fill: parent
                        drag.target: photoFrame
                        scrollGestureEnabled: false  // 2-finger-flick gesture should pass through to the Flickable
                        onPressed: {
                            photoFrame.z = ++root.highestZ;
                            parent.setFrameColor();
                        }
                        onEntered: parent.setFrameColor();
                        onWheel: {
                            if (wheel.modifiers & Qt.ControlModifier) {
                                photoFrame.rotation += wheel.angleDelta.y / 120 * 5;
                                if (Math.abs(photoFrame.rotation) < 4)
                                    photoFrame.rotation = 0;
                            } else {
                                photoFrame.rotation += wheel.angleDelta.x / 120;
                                if (Math.abs(photoFrame.rotation) < 0.6)
                                    photoFrame.rotation = 0;
                                var scaleBefore = photoFrame.scale;
                                photoFrame.scale += photoFrame.scale * wheel.angleDelta.y / 120 / 10;
                            }
                        }
                    }
                    function setFrameColor() {
                        if (currentFrame)
                            currentFrame.border.color = "black";
                        currentFrame = photoFrame;
                        currentFrame.border.color = "red";
                    }
                }
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
}
