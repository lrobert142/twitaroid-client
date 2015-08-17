import QtQuick 2.5
import QtQuick.Dialogs 1.0
import QtQuick.Window 2.1
import QtWebSockets 1.0

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
