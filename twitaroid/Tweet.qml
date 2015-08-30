import QtQuick 2.5


Rectangle {
    height: tweetText.height

    Image {
        id: avatar
        width: 25
        height: 25
        fillMode: Image.PreserveAspectFit
        antialiasing: true
        source: model.avatar
    }

    Text {
        id: author
        anchors {
            left: avatar.right
            leftMargin: 5
        }

        text: model.author + " @" + model.screenname
        font.pointSize: 11
        font.bold: true
        wrapMode: Text.WordWrap
    }

    Text {
        id: tweetText
        width: parent.width - 20
        anchors {
            left: avatar.right
            leftMargin: 5
            top: author.bottom
        }

        text: model.body
        font.pointSize: 10
        wrapMode: Text.WordWrap
    }

    Text {
        id: tweetTime
        anchors {
            left: author.right
            leftMargin: 20
        }

        text: model.date
        font.pointSize: 11
        wrapMode: Text.WordWrap
    }
}
