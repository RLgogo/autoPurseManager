import QtQuick

Item {
    id: root
    property int year: 2026
    property int month: 1
    property int minYear: 2000
    property int maxYear: 2100
    property var theme: ({})

    signal accepted()
    signal canceled()

    onVisibleChanged: {
        if (visible) {
            yearWheel.currentIndex = root.year - root.minYear
            monthWheel.currentIndex = root.month - 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#59000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.canceled()
            onWheel: wheel.accepted = true
        }
    }

    Rectangle {
        width: 320
        height: 400
        anchors.centerIn: parent
        radius: 18
        color: root.theme.card || "#ffffff"

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Year / Month"
                font.pixelSize: Math.round(13 * rootWindow.uiScale)
                color: root.theme.faint || "#9a9a9a"
            }

            Row {
                width: parent.width
                height: 260
                spacing: 12

                Item {
                    width: (parent.width - 12) / 2
                    height: parent.height
                    clip: true

                    ListView {
                        id: yearWheel
                        anchors.fill: parent
                        model: root.maxYear - root.minYear + 1
                        snapMode: ListView.SnapToItem
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: (height - 48) / 2
                        preferredHighlightEnd: (height + 48) / 2

                        delegate: Item {
                            width: yearWheel.width
                            height: Math.round(48 * rootWindow.uiScale)
                            property real dist: Math.abs(y + height / 2 - yearWheel.contentY - yearWheel.height / 2) / 48
                            property bool isCenter: dist < 0.5
                            property int yValue: root.minYear + index

                            Text {
                                anchors.centerIn: parent
                                text: yValue.toString()
                                font.pixelSize: isCenter ? 20 : 16
                                font.bold: isCenter
                                color: root.theme.text || "#1a1a1a"
                                opacity: isCenter ? 1.0 : Math.max(0.15, 1 - dist * 0.3)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0)
                                root.year = root.minYear + currentIndex
                        }
                    }

                    Rectangle {
                        width: parent.width - 8
                        height: Math.round(48 * rootWindow.uiScale)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        border.color: root.theme.border || "#e8e8e8"
                        border.width: 1
                        radius: 8
                    }
                }

                Item {
                    width: (parent.width - 12) / 2
                    height: parent.height
                    clip: true

                    ListView {
                        id: monthWheel
                        anchors.fill: parent
                        model: 12
                        snapMode: ListView.SnapToItem
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: (height - 48) / 2
                        preferredHighlightEnd: (height + 48) / 2

                        delegate: Item {
                            width: monthWheel.width
                            height: Math.round(48 * rootWindow.uiScale)
                            property real dist: Math.abs(y + height / 2 - monthWheel.contentY - monthWheel.height / 2) / 48
                            property bool isCenter: dist < 0.5
                            property int mValue: index + 1

                            Text {
                                anchors.centerIn: parent
                                text: mValue.toString()
                                font.pixelSize: isCenter ? 20 : 16
                                font.bold: isCenter
                                color: root.theme.text || "#1a1a1a"
                                opacity: isCenter ? 1.0 : Math.max(0.15, 1 - dist * 0.3)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0)
                                root.month = currentIndex + 1
                        }
                    }

                    Rectangle {
                        width: parent.width - 8
                        height: Math.round(48 * rootWindow.uiScale)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        border.color: root.theme.border || "#e8e8e8"
                        border.width: 1
                        radius: 8
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 20
                color: root.theme.accent || "#1a1a1a"

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                    color: root.theme.accentText || "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.accepted()
                }
            }
        }
    }
}

