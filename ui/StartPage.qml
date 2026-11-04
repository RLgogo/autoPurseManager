import QtQuick

Item {
    id: startPage
    anchors.fill: parent

    signal loginSuccess()
    signal requestExit()

    property var txt: langManager.texts
    property var theme: themeManager.theme
    property string selectedId: ""
    property string toastMsg: ""
    property int tipIndex: 0
    property var tips: langManager.tips

    Rectangle {
        anchors.fill: parent
        color: startPage.theme.bg
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 64
        spacing: 20

        Item {
            width: parent.width
            height: 64

            Text {
                id: accountTitle
                anchors.centerIn: parent
                text: "Account"
                font.pixelSize: 28
                font.bold: true
                color: startPage.theme.text
            }

            Text {
                id: tipText
                anchors.left: accountTitle.right
                anchors.leftMargin: -30
                anchors.bottom: accountTitle.top
                anchors.bottomMargin: 30
                width: Math.min(170, startPage.width - accountTitle.width / 2 - 40)
                text: startPage.tips.length > 0
                      ? startPage.tips[startPage.tipIndex % startPage.tips.length]
                      : ""
                font.pixelSize: 17
                font.bold: true
                color: "#F7C948"
                wrapMode: Text.WordWrap
                lineHeight: 0.95
                rotation: 14
                transformOrigin: Item.BottomLeft
                scale: 1.0
                opacity: 1.0

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.04; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutSine }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8

            Item {
                id: accountListArea
                width: parent.width
                height: accountColumn.implicitHeight

                property int selectedIndex: {
                    var accounts = accountManager.accounts
                    for (var i = 0; i < accounts.length; ++i) {
                        if (accounts[i].id === startPage.selectedId)
                            return i
                    }
                    return -1
                }

                Column {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: accountManager.accounts
                        delegate: Rectangle {
                            width: parent.width
                            height: 52
                            radius: 12
                            color: startPage.theme.card
                        }
                    }
                }

                Rectangle {
                    id: accountHighlight
                    width: parent.width
                    height: 52
                    radius: 12
                    color: startPage.theme.accent
                    visible: accountListArea.selectedIndex >= 0
                    y: accountListArea.selectedIndex * 60

                    property bool animateY: false

                    Behavior on y {
                        enabled: accountHighlight.animateY
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    onVisibleChanged: {
                        if (visible && !accountHighlight.animateY) {
                            Qt.callLater(function() {
                                accountHighlight.animateY = true
                            })
                        }
                    }
                }

                Column {
                    id: accountColumn
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: accountManager.accounts
                        delegate: Rectangle {
                            id: accountItem
                            width: parent.width
                            height: 52
                            radius: 12
                            color: "transparent"

                            property bool isSelected: startPage.selectedId === modelData.id
                            property real pressScale: 1.0
                            scale: pressScale

                            Behavior on pressScale {
                                NumberAnimation {
                                    duration: 320
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 3.5
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.pixelSize: Math.round(15 * rootWindow.uiScale)
                                font.bold: accountItem.isSelected
                                color: accountItem.isSelected ? startPage.theme.accentText : startPage.theme.text

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: accountManager.currentId === modelData.id ? startPage.txt.current : ""
                                font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                color: accountItem.isSelected ? startPage.theme.faint : startPage.theme.muted

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: accountItem.pressScale = 0.90
                                onReleased: accountItem.pressScale = 1.0
                                onCanceled: accountItem.pressScale = 1.0
                                onClicked: startPage.selectedId = modelData.id
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: createAccountBtn
                width: parent.width
                height: 52
                radius: 12
                color: startPage.theme.card
                border.color: startPage.theme.border
                border.width: 1
                visible: accountManager.count < accountManager.maxAccounts

                property real pressScale: 1.0
                scale: pressScale

                Behavior on pressScale {
                    NumberAnimation {
                        duration: 320
                        easing.type: Easing.OutBack
                        easing.overshoot: 3.5
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: startPage.txt.createAccount
                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                    color: startPage.theme.muted
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: createAccountBtn.pressScale = 0.90
                    onReleased: createAccountBtn.pressScale = 1.0
                    onCanceled: createAccountBtn.pressScale = 1.0
                    onClicked: {
                        accountNameInput.text = ""
                        createDialog.visible = true
                    }
                }
            }
        }

        Rectangle {
            id: loginBtn
            width: parent.width
            height: Math.round(48 * rootWindow.uiScale)
            radius: 24
            color: startPage.selectedId !== "" ? startPage.theme.accent : startPage.theme.border

            property real pressScale: 1.0
            scale: pressScale

            Behavior on pressScale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 3.5
                }
            }

            Text {
                anchors.centerIn: parent
                text: startPage.txt.login
                font.pixelSize: Math.round(15 * rootWindow.uiScale)
                font.bold: true
                color: startPage.selectedId !== "" ? startPage.theme.accentText : startPage.theme.faint
            }

            MouseArea {
                anchors.fill: parent
                onPressed: loginBtn.pressScale = 0.88
                onReleased: loginBtn.pressScale = 1.0
                onCanceled: loginBtn.pressScale = 1.0
                onClicked: {
                    if (startPage.selectedId === "") return
                    var dbPath = accountManager.login(startPage.selectedId)
                    if (dbPath === "") {
                        startPage.toastMsg = "Login failed"
                        toast.opacity = 1
                        toastTimer.restart()
                        return
                    }
                    if (!billModel.reloadForAccount(dbPath)) {
                        startPage.toastMsg = "Database open failed"
                        toast.opacity = 1
                        toastTimer.restart()
                        return
                    }
                    startPage.loginSuccess()
                }
            }
        }

        Rectangle {
            id: exitBtn
            width: parent.width
            height: Math.round(48 * rootWindow.uiScale)
            radius: 24
            color: startPage.theme.card
            border.color: startPage.theme.danger
            border.width: 1

            property real pressScale: 1.0
            scale: pressScale

            Behavior on pressScale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 3.5
                }
            }

            Text {
                anchors.centerIn: parent
                text: startPage.txt.exit
                font.pixelSize: Math.round(15 * rootWindow.uiScale)
                color: startPage.theme.danger
            }

            MouseArea {
                anchors.fill: parent
                onPressed: exitBtn.pressScale = 0.88
                onReleased: exitBtn.pressScale = 1.0
                onCanceled: exitBtn.pressScale = 1.0
                onClicked: exitConfirm1.visible = true
            }
        }
    }

    Item {
        id: createDialog
        anchors.fill: parent
        visible: false
        z: 10

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
            MouseArea {
                anchors.fill: parent
                onClicked: createDialog.visible = false
            }
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 190
            anchors.centerIn: parent
            radius: 16
            color: startPage.theme.card

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: startPage.txt.createNewAccount
                    font.pixelSize: Math.round(16 * rootWindow.uiScale)
                    font.bold: true
                    color: startPage.theme.text
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: startPage.theme.btnBg

                    TextInput {
                        id: accountNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        color: startPage.theme.text
                        selectByMouse: true
                        focus: true
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: startPage.txt.inputAccountName
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        color: startPage.theme.faint
                        visible: accountNameInput.text.length === 0
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        id: createCancelBtn
                        width: (parent.width - 8) / 2
                        height: 40
                        radius: 20
                        color: startPage.theme.btnBg

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: startPage.theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: createCancelBtn.pressScale = 0.88
                            onReleased: createCancelBtn.pressScale = 1.0
                            onCanceled: createCancelBtn.pressScale = 1.0
                            onClicked: createDialog.visible = false
                        }
                    }

                    Rectangle {
                        id: createConfirmBtn
                        width: (parent.width - 8) / 2
                        height: 40
                        radius: 20
                        color: startPage.theme.accent

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.create
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: startPage.theme.accentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: createConfirmBtn.pressScale = 0.88
                            onReleased: createConfirmBtn.pressScale = 1.0
                            onCanceled: createConfirmBtn.pressScale = 1.0
                            onClicked: {
                                var name = accountNameInput.text.trim()
                                if (name === "") return
                                var id = accountManager.createAccount(name)
                                if (id !== "") {
                                    startPage.selectedId = id
                                    createDialog.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: exitConfirm1
        anchors.fill: parent
        visible: false
        z: 20

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 170
            anchors.centerIn: parent
            radius: 16
            color: startPage.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: startPage.txt.confirmExit
                    font.pixelSize: Math.round(16 * rootWindow.uiScale)
                    font.bold: true
                    color: startPage.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: exit1CancelBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: startPage.theme.btnBg

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: startPage.theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: exit1CancelBtn.pressScale = 0.88
                            onReleased: exit1CancelBtn.pressScale = 1.0
                            onCanceled: exit1CancelBtn.pressScale = 1.0
                            onClicked: exitConfirm1.visible = false
                        }
                    }

                    Rectangle {
                        id: exit1NextBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: startPage.theme.accent

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.next
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: startPage.theme.accentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: exit1NextBtn.pressScale = 0.88
                            onReleased: exit1NextBtn.pressScale = 1.0
                            onCanceled: exit1NextBtn.pressScale = 1.0
                            onClicked: {
                                exitConfirm1.visible = false
                                exitConfirm2.visible = true
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: exitConfirm2
        anchors.fill: parent
        visible: false
        z: 21

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 170
            anchors.centerIn: parent
            radius: 16
            color: startPage.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: startPage.txt.confirmExit2
                    font.pixelSize: Math.round(16 * rootWindow.uiScale)
                    font.bold: true
                    color: startPage.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: exit2CancelBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: startPage.theme.btnBg

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: startPage.theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: exit2CancelBtn.pressScale = 0.88
                            onReleased: exit2CancelBtn.pressScale = 1.0
                            onCanceled: exit2CancelBtn.pressScale = 1.0
                            onClicked: exitConfirm2.visible = false
                        }
                    }

                    Rectangle {
                        id: exit2ConfirmBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: startPage.theme.danger

                        property real pressScale: 1.0
                        scale: pressScale

                        Behavior on pressScale {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 3.5
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: startPage.txt.exitAction
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: exit2ConfirmBtn.pressScale = 0.88
                            onReleased: exit2ConfirmBtn.pressScale = 1.0
                            onCanceled: exit2ConfirmBtn.pressScale = 1.0
                            onClicked: {
                                exitConfirm2.visible = false
                                startPage.requestExit()
                            }
                        }
                    }
                }
            }
        }
            Timer {
        id: tipTimer
        interval: 20000
        running: startPage.tips.length > 1
        repeat: true
        onTriggered: {
            tipText.opacity = 0
            tipFadeTimer.restart()
        }
    }

    Timer {
        id: tipFadeTimer
        interval: 400
        onTriggered: {
            startPage.tipIndex = (startPage.tipIndex + 1) % startPage.tips.length
            tipText.opacity = 1
        }
    }
    }

    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        width: toastText.implicitWidth + 32
        height: 40
        radius: 20
        color: startPage.theme.accent
        opacity: 0
        visible: opacity > 0.01
        z: 50

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Text {
            id: toastText
            anchors.centerIn: parent
            text: startPage.toastMsg
            color: startPage.theme.accentText
            font.pixelSize: Math.round(13* rootWindow.uiScale)
        }
    }

    Timer {
        id: toastTimer
        interval: 2500
        onTriggered: toast.opacity = 0
    }
}

