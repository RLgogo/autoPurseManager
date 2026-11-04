import QtQuick

Item {
    id: root

    property var txt: langManager.texts
    property var theme: themeManager.theme
    property var historyData: []
    property int totalCount: 0
    property int pendingDeleteId: -1

    signal toast(string msg)

    function open() {
        refresh()
        visible = true
    }

    function refresh() {
        historyData = billModel.importHistoryList()
        totalCount = billModel.totalBillCount()
    }

    function fmtTime(s) {
        if (!s) return ""
        return s.substring(0, 16).replace("T", " ")
    }

    Rectangle {
        anchors.fill: parent
        color: "#59000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    Rectangle {
        width: parent.width - 40
        height: parent.height - 120
        anchors.centerIn: parent
        radius: 18
        color: root.theme.card

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.txt.history
                    font.pixelSize: Math.round(18 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.txt.totalRecords + root.totalCount + root.txt.recordsUnit
                    font.pixelSize: Math.round(12 * rootWindow.uiScale)
                    color: root.theme.faint
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.border
            }

            Item {
                width: parent.width
                height: parent.height - 28 - 1 - 48 - 24

                ListView {
                    id: histList
                    anchors.fill: parent
                    model: root.historyData
                    clip: true
                    spacing: 8

                    delegate: Rectangle {
                        id: histItem
                        width: histList.width
                        height: 76
                        radius: 10
                        color: root.theme.btnBg

                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 3

                            Row {
                                width: parent.width
                                Text {
                                    width: parent.width - histCount.width
                                    text: modelData.fileName
                                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                                    font.bold: true
                                    color: root.theme.text
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    id: histCount
                                    text: modelData.recordCount + root.txt.recordsUnit
                                    font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                    font.bold: true
                                    color: root.theme.accent
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.txt.from + root.fmtTime(modelData.minTime)
                                      + root.txt.to + root.fmtTime(modelData.maxTime)
                                font.pixelSize: Math.round(10 * rootWindow.uiScale)
                                color: root.theme.muted
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.txt.importedAt + root.fmtTime(modelData.importTime)
                                font.pixelSize: Math.round(10 * rootWindow.uiScale)
                                color: root.theme.faint
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: histItem.pressScale = 0.96
                            onReleased: histItem.pressScale = 1.0
                            onCanceled: histItem.pressScale = 1.0
                            onPressAndHold: {
                                root.pendingDeleteId = modelData.id
                                deleteConfirm1.visible = true
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.historyData.length === 0
                    text: root.txt.historyEmpty
                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                    color: root.theme.faint
                }
            }

            Rectangle {
                id: histCloseBtn
                width: parent.width
                height: 44
                radius: 22
                color: root.theme.btnBg
                property real pressScale: 1.0
                scale: pressScale
                Behavior on pressScale {
                    NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                }
                Text {
                    anchors.centerIn: parent
                    text: root.txt.cancel
                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                    color: root.theme.muted
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: histCloseBtn.pressScale = 0.88
                    onReleased: histCloseBtn.pressScale = 1.0
                    onCanceled: histCloseBtn.pressScale = 1.0
                    onClicked: root.visible = false
                }
            }
        }
    }

    Item {
        id: deleteConfirm1
        anchors.fill: parent
        visible: false
        z: 10

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 170
            anchors.centerIn: parent
            radius: 16
            color: root.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.txt.deleteRecord
                    font.pixelSize: Math.round(15 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: del1Cancel
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.btnBg
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: root.theme.muted
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: del1Cancel.pressScale = 0.88
                            onReleased: del1Cancel.pressScale = 1.0
                            onCanceled: del1Cancel.pressScale = 1.0
                            onClicked: deleteConfirm1.visible = false
                        }
                    }

                    Rectangle {
                        id: del1Next
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.accent
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.txt.next
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: root.theme.accentText
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: del1Next.pressScale = 0.88
                            onReleased: del1Next.pressScale = 1.0
                            onCanceled: del1Next.pressScale = 1.0
                            onClicked: {
                                deleteConfirm1.visible = false
                                deleteConfirm2.visible = true
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: deleteConfirm2
        anchors.fill: parent
        visible: false
        z: 11

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 170
            anchors.centerIn: parent
            radius: 16
            color: root.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.txt.deleteRecord2
                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                    width: 240
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: del2Cancel
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.btnBg
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: root.theme.muted
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: del2Cancel.pressScale = 0.88
                            onReleased: del2Cancel.pressScale = 1.0
                            onCanceled: del2Cancel.pressScale = 1.0
                            onClicked: deleteConfirm2.visible = false
                        }
                    }

                    Rectangle {
                        id: del2Confirm
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.danger
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.txt.deleteAction
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: "#ffffff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: del2Confirm.pressScale = 0.88
                            onReleased: del2Confirm.pressScale = 1.0
                            onCanceled: del2Confirm.pressScale = 1.0
                            onClicked: {
                                deleteConfirm2.visible = false
                                if (billModel.deleteImportHistory(root.pendingDeleteId)) {
                                    root.refresh()
                                    root.toast(root.txt.deleteSuccess)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

