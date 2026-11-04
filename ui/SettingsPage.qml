import QtQuick

Item {
    id: root

    property var txt: langManager.texts
    property var theme: themeManager.theme
    property string currentAccountId: ""
    property string pendingLang: "en"

    signal loggedOut()
    signal accountDeleted()
    signal toast(string msg)

    function open() {
        pendingLang = langManager.currentLang
        var accounts = accountManager.accounts
        for (var i = 0; i < accounts.length; ++i) {
            if (accounts[i].id === currentAccountId) {
                nameInput.text = accounts[i].name
                break
            }
        }
        visible = true
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
        width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
        height: 600
        anchors.centerIn: parent
        radius: 18
        color: root.theme.card

        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: settingsColumn.height
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: settingsColumn
                width: parent.width
                spacing: 14

                Text {
                    text: root.txt.settingsTitle
                    font.pixelSize: Math.round(18 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                }

                Column {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: root.txt.renameAccount
                        font.pixelSize: Math.round(13 * rootWindow.uiScale)
                        color: root.theme.muted
                    }
                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 8
                        color: root.theme.btnBg
                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: root.theme.text
                            selectByMouse: true
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: root.txt.languageLabel
                        font.pixelSize: Math.round(13 * rootWindow.uiScale)
                        color: root.theme.muted
                    }

                    Item {
                        id: langSelector
                        width: parent.width
                        height: 40

                        Rectangle {
                            id: langPill
                            height: 40
                            radius: 8
                            color: root.theme.accent
                            width: langSelector.width / 2
                            x: root.pendingLang === "zh" ? 0 : langSelector.width / 2

                            Behavior on x {
                                NumberAnimation {
                                    duration: 240
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 0

                            Rectangle {
                                id: zhBtn
                                width: parent.width / 2
                                height: 40
                                radius: 8
                                color: "transparent"

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
                                    text: root.txt.chinese
                                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                                    color: root.pendingLang === "zh" ? root.theme.accentText : root.theme.btnText

                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: zhBtn.pressScale = 0.90
                                    onReleased: zhBtn.pressScale = 1.0
                                    onCanceled: zhBtn.pressScale = 1.0
                                    onClicked: root.pendingLang = "zh"
                                }
                            }

                            Rectangle {
                                id: enBtn
                                width: parent.width / 2
                                height: 40
                                radius: 8
                                color: "transparent"

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
                                    text: root.txt.english
                                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                                    color: root.pendingLang === "en" ? root.theme.accentText : root.theme.btnText

                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: enBtn.pressScale = 0.90
                                    onReleased: enBtn.pressScale = 1.0
                                    onCanceled: enBtn.pressScale = 1.0
                                    onClicked: root.pendingLang = "en"
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "transparent"
                            border.color: root.theme.border
                            border.width: 1
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: root.txt.themeLabel
                        font.pixelSize: Math.round(13 * rootWindow.uiScale)
                        color: root.theme.muted
                    }
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8
                        Repeater {
                            model: themeManager.availableThemes
                            delegate: Rectangle {
                                id: themeCard
                                width: (parent.width - 8) / 2
                                height: Math.round(48 * rootWindow.uiScale)
                                radius: 8
                                color: modelData.bg
                                border.color: themeManager.currentThemeId === modelData.id
                                              ? root.theme.accent
                                              : root.theme.border
                                border.width: themeManager.currentThemeId === modelData.id ? 2 : 1

                                property real pressScale: 1.0
                                scale: pressScale

                                Behavior on pressScale {
                                    NumberAnimation {
                                        duration: 320
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 3.5
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: modelData.accent
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        color: modelData.text
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: themeCard.pressScale = 0.88
                                    onReleased: themeCard.pressScale = 1.0
                                    onCanceled: themeCard.pressScale = 1.0
                                    onClicked: themeManager.setTheme(modelData.id)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: applyBtn
                    width: parent.width
                    height: 44
                    radius: 22
                    color: root.theme.accent

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
                        text: root.txt.apply
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        font.bold: true
                        color: root.theme.accentText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: applyBtn.pressScale = 0.88
                        onReleased: applyBtn.pressScale = 1.0
                        onCanceled: applyBtn.pressScale = 1.0
                        onClicked: {
                            var n = nameInput.text.trim()
                            if (n !== "")
                                accountManager.renameAccount(root.currentAccountId, n)
                            if (root.pendingLang !== langManager.currentLang)
                                langManager.setLanguage(root.pendingLang)
                            root.toast(root.txt.saved)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.theme.border
                }

                Rectangle {
                    id: logoutBtn
                    width: parent.width
                    height: 44
                    radius: 22
                    color: root.theme.btnBg

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
                        text: root.txt.logout
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        font.bold: true
                        color: root.theme.btnText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: logoutBtn.pressScale = 0.88
                        onReleased: logoutBtn.pressScale = 1.0
                        onCanceled: logoutBtn.pressScale = 1.0
                        onClicked: root.loggedOut()
                    }
                }

                Rectangle {
                    id: deleteBtn
                    width: parent.width
                    height: 44
                    radius: 22
                    color: root.theme.dangerBg

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
                        text: root.txt.deleteAccount
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        font.bold: true
                        color: root.theme.danger
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: deleteBtn.pressScale = 0.88
                        onReleased: deleteBtn.pressScale = 1.0
                        onCanceled: deleteBtn.pressScale = 1.0
                        onClicked: {
                            if (accountManager.count <= 1 || root.currentAccountId === "default") {
                                root.toast(root.txt.cannotDelete)
                                return
                            }
                            deleteConfirm1.visible = true
                        }
                    }
                }

                Rectangle {
                    id: cancelBtn
                    width: parent.width
                    height: 40
                    radius: 20
                    color: root.theme.btnBg

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
                        text: root.txt.cancel
                        font.pixelSize: Math.round(14 * rootWindow.uiScale)
                        color: root.theme.muted
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: cancelBtn.pressScale = 0.88
                        onReleased: cancelBtn.pressScale = 1.0
                        onCanceled: cancelBtn.pressScale = 1.0
                        onClicked: root.visible = false
                    }
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
                    text: root.txt.deleteConfirm1
                    font.pixelSize: Math.round(15 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: del1CancelBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.btnBg

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
                            text: root.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: root.theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: del1CancelBtn.pressScale = 0.88
                            onReleased: del1CancelBtn.pressScale = 1.0
                            onCanceled: del1CancelBtn.pressScale = 1.0
                            onClicked: deleteConfirm1.visible = false
                        }
                    }

                    Rectangle {
                        id: del1NextBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.accent

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
                            text: root.txt.next
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: root.theme.accentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: del1NextBtn.pressScale = 0.88
                            onReleased: del1NextBtn.pressScale = 1.0
                            onCanceled: del1NextBtn.pressScale = 1.0
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
                    text: root.txt.deleteConfirm2
                    font.pixelSize: Math.round(15 * rootWindow.uiScale)
                    font.bold: true
                    color: root.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: del2CancelBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.btnBg

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
                            text: root.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: root.theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: del2CancelBtn.pressScale = 0.88
                            onReleased: del2CancelBtn.pressScale = 1.0
                            onCanceled: del2CancelBtn.pressScale = 1.0
                            onClicked: deleteConfirm2.visible = false
                        }
                    }

                    Rectangle {
                        id: del2ConfirmBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: root.theme.danger

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
                            text: root.txt.deleteAction
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: del2ConfirmBtn.pressScale = 0.88
                            onReleased: del2ConfirmBtn.pressScale = 1.0
                            onCanceled: del2ConfirmBtn.pressScale = 1.0
                            onClicked: {
                                deleteConfirm2.visible = false
                                if (accountManager.removeAccount(root.currentAccountId)) {
                                    root.visible = false
                                    root.accountDeleted()
                                } else {
                                    root.toast(root.txt.cannotDelete)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

