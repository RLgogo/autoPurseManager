import QtQuick
import QtQuick.Window
import QtQuick.Dialogs

Window {
    id: rootWindow
    visible: true
    width: Qt.platform.os === "android" || Qt.platform.os === "ios"
           ? Screen.width
           : Math.min(Screen.width, 480)
    height: Qt.platform.os === "android" || Qt.platform.os === "ios"
            ? Screen.height
            : Math.min(Screen.height, 900)
    title: rootWindow.txt.appTitle
    color: rootWindow.theme.bg

    readonly property real uiScale: Math.min(width / 420, height / 860)

    property string appState: "start"
    property string currentPage: "overview"
    property bool allowClose: false

    property bool weekNetMode: false
    property bool weekInvertY: false
    property bool monthNetMode: false
    property bool monthInvertY: false
    property bool dailyNetMode: false
    property bool dailyInvertY: false
    property bool yearNetMode: false
    property bool yearInvertY: false
    property real lastBackPressTime: 0
    property bool pendingExitAfterImport: false

    property var txt: langManager.texts
    property var theme: themeManager.theme
    property bool isDark: themeManager.currentThemeId.indexOf("dark") === 0

    property color weekColor: isDark ? "#63b3ed" : "#4a90e2"
    property color monthColor: isDark ? "#ed8936" : "#e28b4a"
    property color dailyColor: isDark ? "#a78bfa" : "#8e6fd0"
    property color yearColor: isDark ? "#68d391" : "#5bbf7a"
    property color alphaColor: isDark ? "#fc8181" : "#e05c5c"
    property color betaColor: isDark ? "#4fd1c5" : "#3fb6c4"

    property var weekData: {
        billModel.categoriesRevision
        return billModel ? billModel.dailyExpense(7) : []
    }
    property var monthData: {
        billModel.categoriesRevision
        return billModel ? billModel.dailyExpense(30) : []
    }
    property real weekAvg: {
        var d = rootWindow.weekNetMode ? rootWindow.weekNetData : rootWindow.weekData
        if (d.length === 0) return 0
        var s = 0
        for (var i = 0; i < d.length; ++i) s += d[i].amount
        return s / d.length
    }
    property real monthAvg: {
        var d = rootWindow.monthNetMode ? rootWindow.monthNetData : rootWindow.monthData
        if (d.length === 0) return 0
        var s = 0
        for (var i = 0; i < d.length; ++i) s += d[i].amount
        return s / d.length
    }

    property var weekNetData: {
        billModel.categoriesRevision
        return billModel ? billModel.dailyNet(7) : []
    }
    property var monthNetData: {
        billModel.categoriesRevision
        return billModel ? billModel.dailyNet(30) : []
    }
    property var monthDailyNetData: {
        billModel.categoriesRevision
        return billModel ? billModel.monthDailyNet(rootWindow.monthYear, rootWindow.monthMonth) : []
    }
    property var yearNetData: {
        billModel.categoriesRevision
        return billModel ? billModel.monthlyNet(rootWindow.selectedYear) : []
    }

    property int monthYear: new Date().getFullYear()
    property int monthMonth: new Date().getMonth() + 1
    property var monthDailyData: {
        billModel.categoriesRevision
        return billModel ? billModel.monthDailyExpense(rootWindow.monthYear, rootWindow.monthMonth) : []
    }
    property real monthDailyTotalAmount: {
        var d = rootWindow.dailyNetMode ? rootWindow.monthDailyNetData : rootWindow.monthDailyData
        var s = 0
        for (var i = 0; i < d.length; ++i) s += d[i].amount
        return s
    }

    property int alphaYear: monthMonth === 1 ? monthYear - 1 : monthYear
    property int alphaMonth: monthMonth === 1 ? 12 : monthMonth - 1
    property int betaYear: monthMonth === 12 ? monthYear + 1 : monthYear
    property int betaMonth: monthMonth === 12 ? 1 : monthMonth - 2
    property bool showOverlay: false
    property string overlayTarget: ""
    property var extraSeries: {
        var _d = rootWindow.alphaYear * 10000 + rootWindow.alphaMonth * 100
               + rootWindow.betaYear + rootWindow.betaMonth
               + (rootWindow.showOverlay ? 1 : 0)
               + (rootWindow.dailyNetMode ? 1 : 0)
               + billModel.categoriesRevision
        if (!rootWindow.showOverlay) return []
        var list = []
        var a = billModel
            ? (rootWindow.dailyNetMode
                ? billModel.monthDailyNet(rootWindow.alphaYear, rootWindow.alphaMonth)
                : billModel.monthDailyExpense(rootWindow.alphaYear, rootWindow.alphaMonth))
            : []
        var b = billModel
            ? (rootWindow.dailyNetMode
                ? billModel.monthDailyNet(rootWindow.betaYear, rootWindow.betaMonth)
                : billModel.monthDailyExpense(rootWindow.betaYear, rootWindow.betaMonth))
            : []
        if (a.length > 0) list.push({ "data": a, "color": rootWindow.alphaColor })
        if (b.length > 0) list.push({ "data": b, "color": rootWindow.betaColor })
        return list
    }

    property var categoryData: {
        billModel.categoriesRevision
        return billModel ? billModel.categoryExpense(30) : []
    }

    property int selectedYear: new Date().getFullYear()
    property var yearData: {
        billModel.categoriesRevision
        return billModel ? billModel.monthlyExpense(rootWindow.selectedYear) : []
    }
    property real yearTotalAmount: {
        var d = rootWindow.yearNetMode ? rootWindow.yearNetData : rootWindow.yearData
        var s = 0
        for (var i = 0; i < d.length; ++i) s += d[i].amount
        return s
    }
    property int alphaYearCmp: selectedYear - 1
    property int betaYearCmp: selectedYear - 2
    property bool showYearOverlay: false
    property string yearOverlayTarget: ""
    property var yearExtraSeries: {
        var _d = rootWindow.alphaYearCmp + rootWindow.betaYearCmp
               + (rootWindow.showYearOverlay ? 1 : 0)
               + (rootWindow.yearNetMode ? 1 : 0)
               + billModel.categoriesRevision
        if (!rootWindow.showYearOverlay) return []
        var list = []
        var a = billModel
            ? (rootWindow.yearNetMode
                ? billModel.monthlyNet(rootWindow.alphaYearCmp)
                : billModel.monthlyExpense(rootWindow.alphaYearCmp))
            : []
        var b = billModel
            ? (rootWindow.yearNetMode
                ? billModel.monthlyNet(rootWindow.betaYearCmp)
                : billModel.monthlyExpense(rootWindow.betaYearCmp))
            : []
        if (a.length > 0) list.push({ "data": a, "color": rootWindow.alphaColor })
        if (b.length > 0) list.push({ "data": b, "color": rootWindow.betaColor })
        return list
    }

    property bool showForecast: false
    property var lightForecast: {
        billModel.categoriesRevision
        return billModel ? billModel.yearlyForecast(rootWindow.selectedYear, false) : []
    }
    property var longForecast: {
        billModel.categoriesRevision
        return billModel ? billModel.yearlyForecast(rootWindow.selectedYear, true) : []
    }
    property bool longForecastReady: {
        billModel.categoriesRevision
        return billModel ? billModel.hasLongForecast() : false
    }

    property int topMerchYear: new Date().getFullYear()
    property int topMerchMonth: new Date().getMonth() + 1
    property bool topMerchAll: false
    property var topMerchantsData: {
        billModel.categoriesRevision
        if (!billModel) return []
        if (rootWindow.topMerchAll) return billModel.topMerchantsAll(6)
        return billModel.topMerchants(rootWindow.topMerchYear, rootWindow.topMerchMonth, 6)
    }
    property real topMerchTotal: {
        var _d = rootWindow.topMerchAll
               + rootWindow.topMerchYear * 100 + rootWindow.topMerchMonth
               + billModel.categoriesRevision
        if (!billModel) return 0
        if (_d && rootWindow.topMerchAll) return billModel.totalExpenseAll()
        return billModel.monthDailyTotal(rootWindow.topMerchYear, rootWindow.topMerchMonth)
    }

    onClosing: function(close) {
        if (billModel.importing) {
            close.accepted = false
            importExitTimer.start()
            return
        }
        if (rootWindow.allowClose) return
        close.accepted = false

        var now = Date.now()
        if (appExitConfirm.visible) {
            if (now - rootWindow.lastBackPressTime < 500) {
                rootWindow.allowClose = true
                rootWindow.close()
                return
            }
            rootWindow.lastBackPressTime = now
            appExitFlash.start()
        } else {
            rootWindow.lastBackPressTime = now
            appExitConfirm.visible = true
        }
    }

    StartPage {
        anchors.fill: parent
        visible: rootWindow.appState === "start"
        theme: rootWindow.theme
        onLoginSuccess: rootWindow.appState = "main"
        onRequestExit: {
            rootWindow.allowClose = true
            rootWindow.close()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0
        visible: rootWindow.appState === "main"

        Rectangle {
            id: toolbarRect
            width: parent.width
            height: 56
            color: rootWindow.theme.card

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: rootWindow.txt.appTitle
                font.pixelSize: Math.round(18 * rootWindow.uiScale)
                font.bold: true
                color: rootWindow.theme.text
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    id: billBtn
                    width: billBtnText.implicitWidth + 20
                    height: Math.round(32 * rootWindow.uiScale)
                    radius: 16
                    color: billMenu.visible ? rootWindow.theme.accent : rootWindow.theme.btnBg
                    property real pressScale: 1.0
                    scale: pressScale
                    Behavior on pressScale {
                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                    }
                    Text {
                        id: billBtnText
                        anchors.centerIn: parent
                        text: rootWindow.txt.bill
                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                        color: billMenu.visible ? rootWindow.theme.accentText : rootWindow.theme.btnText
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: billBtn.pressScale = 0.90
                        onReleased: billBtn.pressScale = 1.0
                        onCanceled: billBtn.pressScale = 1.0
                        onClicked: billMenu.visible = !billMenu.visible
                    }
                }

                Item {
                    id: pageSelector
                    width: overviewBtn.width + 6 + detailBtn.width
                    height: Math.round(32 * rootWindow.uiScale)
                    Rectangle {
                        id: pagePill
                        height: Math.round(32 * rootWindow.uiScale)
                        radius: 16
                        color: rootWindow.theme.accent
                        width: currentPage === "overview" ? overviewBtn.width : detailBtn.width
                        x: currentPage === "overview" ? 0 : overviewBtn.width + 6
                        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        spacing: 6

                        Rectangle {
                            id: overviewBtn
                            width: overviewBtnText.implicitWidth + 20
                            height: Math.round(32 * rootWindow.uiScale)
                            radius: 16
                            color: "transparent"
                            property real pressScale: 1.0
                            scale: pressScale
                            Behavior on pressScale {
                                NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                            }
                            Text {
                                id: overviewBtnText
                                anchors.centerIn: parent
                                text: rootWindow.txt.overview
                                font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                color: currentPage === "overview" ? rootWindow.theme.accentText : rootWindow.theme.muted
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: overviewBtn.pressScale = 0.90
                                onReleased: overviewBtn.pressScale = 1.0
                                onCanceled: overviewBtn.pressScale = 1.0
                                onClicked: currentPage = "overview"
                            }
                        }

                        Rectangle {
                            id: detailBtn
                            width: detailBtnText.implicitWidth + 20
                            height: Math.round(32 * rootWindow.uiScale)
                            radius: 16
                            color: "transparent"
                            property real pressScale: 1.0
                            scale: pressScale
                            Behavior on pressScale {
                                NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                            }
                            Text {
                                id: detailBtnText
                                anchors.centerIn: parent
                                text: rootWindow.txt.detail
                                font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                color: currentPage === "detail" ? rootWindow.theme.accentText : rootWindow.theme.muted
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: detailBtn.pressScale = 0.90
                                onReleased: detailBtn.pressScale = 1.0
                                onCanceled: detailBtn.pressScale = 1.0
                                onClicked: currentPage = "detail"
                            }
                        }
                    }
                }

                Rectangle {
                    id: settingsBtn
                    width: settingsBtnText.implicitWidth + 20
                    height: Math.round(32 * rootWindow.uiScale)
                    radius: 16
                    color: rootWindow.theme.btnBg
                    property real pressScale: 1.0
                    scale: pressScale
                    Behavior on pressScale {
                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                    }
                    Text {
                        id: settingsBtnText
                        anchors.centerIn: parent
                        text: rootWindow.txt.settingsLabel
                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                        color: rootWindow.theme.btnText
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: settingsBtn.pressScale = 0.90
                        onReleased: settingsBtn.pressScale = 1.0
                        onCanceled: settingsBtn.pressScale = 1.0
                        onClicked: settingsPage.open()
                    }
                }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 56
            visible: currentPage === "overview"
            contentHeight: overviewColumn.height + 32
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: overviewColumn
                width: parent.width
                spacing: 16
                topPadding: 16
                bottomPadding: 16

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(260 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text { text: rootWindow.txt.thisWeek; font.pixelSize: Math.round(14 * rootWindow.uiScale); font.bold: true; color: rootWindow.theme.text }
                        Row {
                            spacing: 6
                            Rectangle {
                                id: weekNetBtn
                                width: weekNetBtnText.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: rootWindow.weekNetMode ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: weekNetBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.netMode
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.weekNetMode ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: weekNetBtn.pressScale = 0.88
                                    onReleased: weekNetBtn.pressScale = 1.0
                                    onCanceled: weekNetBtn.pressScale = 1.0
                                    onClicked: rootWindow.weekNetMode = !rootWindow.weekNetMode
                                }
                            }
                            Rectangle {
                                id: weekInvertBtn
                                width: weekInvertBtnText.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: rootWindow.weekInvertY ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: weekInvertBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.invertY
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.weekInvertY ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: weekInvertBtn.pressScale = 0.88
                                    onReleased: weekInvertBtn.pressScale = 1.0
                                    onCanceled: weekInvertBtn.pressScale = 1.0
                                    onClicked: rootWindow.weekInvertY = !rootWindow.weekInvertY
                                }
                            }
                        }
                        LineChart {
                            width: parent.width
                            height: 186
                            chartData: rootWindow.weekNetMode ? rootWindow.weekNetData : rootWindow.weekData
                            lineColor: rootWindow.weekColor
                            viewDays: 7
                            theme: rootWindow.theme
                            isDark: rootWindow.isDark
                            invertY: rootWindow.weekInvertY
                            avgText: {
                                var v = rootWindow.weekAvg
                                return rootWindow.txt.avgDaily + (v < 0 ? "-¥" : "¥") + Math.abs(v).toFixed(2)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(260 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text { text: rootWindow.txt.thisMonth; font.pixelSize: Math.round(14 * rootWindow.uiScale); font.bold: true; color: rootWindow.theme.text }
                        Row {
                            spacing: 6
                            Rectangle {
                                id: monthNetBtn
                                width: monthNetBtnText.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: rootWindow.monthNetMode ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: monthNetBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.netMode
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.monthNetMode ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: monthNetBtn.pressScale = 0.88
                                    onReleased: monthNetBtn.pressScale = 1.0
                                    onCanceled: monthNetBtn.pressScale = 1.0
                                    onClicked: rootWindow.monthNetMode = !rootWindow.monthNetMode
                                }
                            }
                            Rectangle {
                                id: monthInvertBtn
                                width: monthInvertBtnText.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: rootWindow.monthInvertY ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: monthInvertBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.invertY
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.monthInvertY ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: monthInvertBtn.pressScale = 0.88
                                    onReleased: monthInvertBtn.pressScale = 1.0
                                    onCanceled: monthInvertBtn.pressScale = 1.0
                                    onClicked: rootWindow.monthInvertY = !rootWindow.monthInvertY
                                }
                            }
                        }
                        LineChart {
                            width: parent.width
                            height: 186
                            chartData: rootWindow.monthNetMode ? rootWindow.monthNetData : rootWindow.monthData
                            lineColor: rootWindow.monthColor
                            viewDays: 15
                            theme: rootWindow.theme
                            isDark: rootWindow.isDark
                            invertY: rootWindow.monthInvertY
                            avgText: {
                                var v = rootWindow.monthAvg
                                return rootWindow.txt.avgDaily + (v < 0 ? "-¥" : "¥") + Math.abs(v).toFixed(2)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(320 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6
                        Item {
                            width: parent.width
                            height: 24
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: ymBtnMainText.implicitWidth + 16
                                height: 24
                                radius: 12
                                color: rootWindow.theme.btnBg
                                Text {
                                    id: ymBtnMainText
                                    anchors.centerIn: parent
                                    text: rootWindow.monthYear + "-" + rootWindow.monthMonth
                                    font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                    font.bold: true
                                    color: rootWindow.theme.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        ymWheelMain.year = rootWindow.monthYear
                                        ymWheelMain.month = rootWindow.monthMonth
                                        ymWheelMain.visible = true
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Rectangle {
                                    id: dailyNetBtn
                                    width: dailyNetBtnText.implicitWidth + 14
                                    height: 22
                                    radius: 11
                                    color: rootWindow.dailyNetMode ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                    property real pressScale: 1.0
                                    scale: pressScale
                                    Behavior on pressScale {
                                        NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                    }
                                    Text {
                                        id: dailyNetBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.netMode
                                        font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                        color: rootWindow.dailyNetMode ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: dailyNetBtn.pressScale = 0.88
                                        onReleased: dailyNetBtn.pressScale = 1.0
                                        onCanceled: dailyNetBtn.pressScale = 1.0
                                        onClicked: rootWindow.dailyNetMode = !rootWindow.dailyNetMode
                                    }
                                }
                                Rectangle {
                                    id: dailyInvertBtn
                                    width: dailyInvertBtnText.implicitWidth + 14
                                    height: 22
                                    radius: 11
                                    color: rootWindow.dailyInvertY ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                    property real pressScale: 1.0
                                    scale: pressScale
                                    Behavior on pressScale {
                                        NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                    }
                                    Text {
                                        id: dailyInvertBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.invertY
                                        font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                        color: rootWindow.dailyInvertY ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: dailyInvertBtn.pressScale = 0.88
                                        onReleased: dailyInvertBtn.pressScale = 1.0
                                        onCanceled: dailyInvertBtn.pressScale = 1.0
                                        onClicked: rootWindow.dailyInvertY = !rootWindow.dailyInvertY
                                    }
                                }
                            }
                        }
                        Item {
                            width: parent.width
                            height: 24
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Rectangle {
                                    width: alphaBtnText.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.showOverlay ? rootWindow.theme.dangerBg : rootWindow.theme.btnBg
                                    Text {
                                        id: alphaBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.alpha + rootWindow.alphaYear + "-" + rootWindow.alphaMonth
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        color: rootWindow.alphaColor
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            rootWindow.overlayTarget = "alpha"
                                            ymWheelOverlay.year = rootWindow.alphaYear
                                            ymWheelOverlay.month = rootWindow.alphaMonth
                                            ymWheelOverlay.visible = true
                                        }
                                    }
                                }
                                Rectangle {
                                    width: betaBtnText.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.showOverlay ? (rootWindow.isDark ? "#1a3a3a" : "#e9f6f8") : rootWindow.theme.btnBg
                                    Text {
                                        id: betaBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.beta + rootWindow.betaYear + "-" + rootWindow.betaMonth
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        color: rootWindow.betaColor
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            rootWindow.overlayTarget = "beta"
                                            ymWheelOverlay.year = rootWindow.betaYear
                                            ymWheelOverlay.month = rootWindow.betaMonth
                                            ymWheelOverlay.visible = true
                                        }
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: rootWindow.txt.compare; font.pixelSize: Math.round(12 * rootWindow.uiScale); color: rootWindow.theme.faint }
                                Rectangle {
                                    width: 40
                                    height: 22
                                    radius: 11
                                    color: rootWindow.showOverlay ? rootWindow.theme.accent : rootWindow.theme.border
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: rootWindow.theme.card
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: rootWindow.showOverlay ? parent.width - 20 : 3
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: rootWindow.showOverlay = !rootWindow.showOverlay
                                    }
                                }
                            }
                        }
                        LineChart {
                            width: parent.width
                            height: 186
                            chartData: rootWindow.dailyNetMode ? rootWindow.monthDailyNetData : rootWindow.monthDailyData
                            lineColor: rootWindow.dailyColor
                            viewDays: -1
                            extraSeries: rootWindow.extraSeries
                            theme: rootWindow.theme
                            isDark: rootWindow.isDark
                            invertY: rootWindow.dailyInvertY
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(400 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8
                        Text { text: rootWindow.txt.category; font.pixelSize: Math.round(14 * rootWindow.uiScale); font.bold: true; color: rootWindow.theme.text }
                        PieChart {
                            width: parent.width
                            height: 210
                            chartData: rootWindow.categoryData
                            theme: rootWindow.theme
                            isDark: rootWindow.isDark
                        }
                        Grid {
                            anchors.horizontalCenter: parent.horizontalCenter
                            columns: 2
                            columnSpacing: 24
                            rowSpacing: 8
                            Repeater {
                                model: rootWindow.categoryData
                                delegate: Row {
                                    spacing: 6
                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: {
                                            var p = ["#4a90e2", "#e28b4a", "#5bbf7a", "#e05c5c",
                                                     "#8e6fd0", "#3fb6c4", "#d4a93a", "#9a9a9a"]
                                            return p[index % p.length]
                                        }
                                    }
                                    Text { text: modelData.category; font.pixelSize: Math.round(11 * rootWindow.uiScale); color: rootWindow.theme.muted; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: Number(modelData.amount).toFixed(0); font.pixelSize: Math.round(11 * rootWindow.uiScale); font.bold: true; color: rootWindow.theme.text; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(380 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 24
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: yearBtnYear.implicitWidth + 16
                                height: 24
                                radius: 12
                                color: rootWindow.theme.btnBg
                                Text {
                                    id: yearBtnYear
                                    anchors.centerIn: parent
                                    text: rootWindow.selectedYear
                                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                                    font.bold: true
                                    color: rootWindow.theme.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        yearPicker.year = rootWindow.selectedYear
                                        yearPicker.visible = true
                                    }
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    var v = rootWindow.yearTotalAmount
                                    return rootWindow.txt.yearTotal + (v < 0 ? "-" : "") + Math.abs(v).toFixed(2)
                                }
                                font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                color: rootWindow.isDark
                                       ? rootWindow.theme.muted
                                       : rootWindow.theme.faint
                            }
                        }

                        Item {
                            width: parent.width
                            height: 24
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Rectangle {
                                    width: alphaYearBtn.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.showYearOverlay ? rootWindow.theme.dangerBg : rootWindow.theme.btnBg
                                    Text {
                                        id: alphaYearBtn
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.alpha + rootWindow.alphaYearCmp
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        color: rootWindow.alphaColor
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            rootWindow.yearOverlayTarget = "alpha"
                                            yearCmpWheel.year = rootWindow.alphaYearCmp
                                            yearCmpWheel.visible = true
                                        }
                                    }
                                }
                                Rectangle {
                                    width: betaYearBtn.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.showYearOverlay ? (rootWindow.isDark ? "#1a3a3a" : "#e9f6f8") : rootWindow.theme.btnBg
                                    Text {
                                        id: betaYearBtn
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.beta + rootWindow.betaYearCmp
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        color: rootWindow.betaColor
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            rootWindow.yearOverlayTarget = "beta"
                                            yearCmpWheel.year = rootWindow.betaYearCmp
                                            yearCmpWheel.visible = true
                                        }
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: rootWindow.txt.compare; font.pixelSize: Math.round(12 * rootWindow.uiScale); color: rootWindow.theme.faint }
                                Rectangle {
                                    width: 40
                                    height: 22
                                    radius: 11
                                    color: rootWindow.showYearOverlay ? rootWindow.theme.accent : rootWindow.theme.border
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: rootWindow.theme.card
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: rootWindow.showYearOverlay ? parent.width - 20 : 3
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: rootWindow.showYearOverlay = !rootWindow.showYearOverlay
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 24
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Row {
                                    spacing: 4
                                    Rectangle {
                                        width: 16
                                        height: 3
                                        radius: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: rootWindow.isDark ? "#63b3ed" : "#4a90e2"
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: rootWindow.txt.forecastLight
                                        font.pixelSize: Math.round(10 * rootWindow.uiScale)
                                        color: rootWindow.theme.muted
                                    }
                                }
                                Row {
                                    spacing: 4
                                    Rectangle {
                                        width: 16
                                        height: 3
                                        radius: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: rootWindow.longForecastReady ? "#f6ad55" : rootWindow.theme.border
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: rootWindow.longForecastReady
                                              ? rootWindow.txt.forecastLong
                                              : rootWindow.txt.forecastNeedMore
                                        font.pixelSize: Math.round(10 * rootWindow.uiScale)
                                color: rootWindow.isDark
                                       ? rootWindow.theme.muted
                                       : rootWindow.theme.faint
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: rootWindow.txt.forecast; font.pixelSize: Math.round(12 * rootWindow.uiScale); color: rootWindow.theme.faint }
                                Rectangle {
                                    width: 40
                                    height: 22
                                    radius: 11
                                    color: rootWindow.showForecast ? rootWindow.theme.accent : rootWindow.theme.border
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: rootWindow.theme.card
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: rootWindow.showForecast ? parent.width - 20 : 3
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: rootWindow.showForecast = !rootWindow.showForecast
                                    }
                                }
                            }
                        }
                        Row {
                            spacing: 6
                            Rectangle {
                                id: yearNetBtn
                                width: yearNetBtnText.implicitWidth + 14
                                height: 22
                                radius: 11
                                color: rootWindow.yearNetMode ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: yearNetBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.netMode
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.yearNetMode ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: yearNetBtn.pressScale = 0.88
                                    onReleased: yearNetBtn.pressScale = 1.0
                                    onCanceled: yearNetBtn.pressScale = 1.0
                                    onClicked: rootWindow.yearNetMode = !rootWindow.yearNetMode
                                }
                            }
                            Rectangle {
                                id: yearInvertBtn
                                width: yearInvertBtnText.implicitWidth + 14
                                height: 22
                                radius: 11
                                color: rootWindow.yearInvertY ? rootWindow.theme.accent : rootWindow.theme.btnBg
                                property real pressScale: 1.0
                                scale: pressScale
                                Behavior on pressScale {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                }
                                Text {
                                    id: yearInvertBtnText
                                    anchors.centerIn: parent
                                    text: rootWindow.txt.invertY
                                    font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                    color: rootWindow.yearInvertY ? rootWindow.theme.accentText : rootWindow.theme.btnText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: yearInvertBtn.pressScale = 0.88
                                    onReleased: yearInvertBtn.pressScale = 1.0
                                    onCanceled: yearInvertBtn.pressScale = 1.0
                                    onClicked: rootWindow.yearInvertY = !rootWindow.yearInvertY
                                }
                            }
                        }

                        LineChart {
                            width: parent.width
                            height: 186
                            chartData: rootWindow.yearNetMode ? rootWindow.yearNetData : rootWindow.yearData
                            lineColor: rootWindow.yearColor
                            viewDays: 12
                            dateSuffix: rootWindow.txt.monthUnit
                            theme: rootWindow.theme
                            isDark: rootWindow.isDark
                            invertY: rootWindow.yearInvertY
                            extraSeries: {
                                var list = []
                                if (rootWindow.showYearOverlay)
                                    list = list.concat(rootWindow.yearExtraSeries)
                                if (rootWindow.showForecast) {
                                    if (rootWindow.lightForecast.length > 0)
                                        list.push({ "data": rootWindow.lightForecast,
                                                    "color": rootWindow.isDark ? "#63b3ed" : "#4a90e2",
                                                    "dash": true })
                                    if (rootWindow.longForecastReady && rootWindow.longForecast.length > 0)
                                        list.push({ "data": rootWindow.longForecast,
                                                    "color": "#f6ad55",
                                                    "dash": true })
                                }
                                return list
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 32
                    x: 16
                    height: Math.round(380 * rootWindow.uiScale)
                    radius: 12
                    color: rootWindow.theme.card
                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        Item {
                            width: parent.width
                            height: 24
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Rectangle {
                                    id: allBtn
                                    width: allBtnText.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.topMerchAll
                                           ? rootWindow.theme.accent
                                           : rootWindow.theme.btnBg
                                    property real pressScale: 1.0
                                    scale: pressScale
                                    Behavior on pressScale {
                                        NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                    }
                                    Text {
                                        id: allBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.txt.all
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        font.bold: true
                                        color: rootWindow.topMerchAll
                                               ? rootWindow.theme.accentText
                                               : rootWindow.theme.btnText
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: allBtn.pressScale = 0.88
                                        onReleased: allBtn.pressScale = 1.0
                                        onCanceled: allBtn.pressScale = 1.0
                                        onClicked: rootWindow.topMerchAll = true
                                    }
                                }
                                Rectangle {
                                    id: topMerchBtn
                                    width: topMerchBtnText.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: rootWindow.topMerchAll
                                           ? rootWindow.theme.btnBg
                                           : rootWindow.theme.accent
                                    property real pressScale: 1.0
                                    scale: pressScale
                                    Behavior on pressScale {
                                        NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                                    }
                                    Text {
                                        id: topMerchBtnText
                                        anchors.centerIn: parent
                                        text: rootWindow.topMerchYear + "-" + rootWindow.topMerchMonth
                                        font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                        font.bold: true
                                        color: rootWindow.topMerchAll
                                               ? rootWindow.theme.btnText
                                               : rootWindow.theme.accentText
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: topMerchBtn.pressScale = 0.88
                                        onReleased: topMerchBtn.pressScale = 1.0
                                        onCanceled: topMerchBtn.pressScale = 1.0
                                        onClicked: {
                                            rootWindow.topMerchAll = false
                                            ymWheelTopMerch.year = rootWindow.topMerchYear
                                            ymWheelTopMerch.month = rootWindow.topMerchMonth
                                            ymWheelTopMerch.visible = true
                                        }
                                    }
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    var v = rootWindow.topMerchTotal
                                    return rootWindow.txt.total + (v < 0 ? "-" : "") + Math.abs(v).toFixed(2)
                                }
                                font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                color: rootWindow.isDark
                                       ? rootWindow.theme.muted
                                       : rootWindow.theme.faint
                            }
                        }
                        Text {
                            text: rootWindow.txt.topMerchants
                            font.pixelSize: Math.round(11 * rootWindow.uiScale)
                            color: rootWindow.theme.faint
                        }
                        Repeater {
                            model: rootWindow.topMerchantsData
                            delegate: Item {
                                width: parent.width
                                height: 40
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    color: index === 0 ? rootWindow.theme.accent
                                         : index === 1 ? rootWindow.theme.muted
                                         : index === 2 ? rootWindow.theme.faint
                                         : rootWindow.theme.grid
                                    Text {
                                        anchors.centerIn: parent
                                        text: (index + 1).toString()
                                        font.pixelSize: Math.round(11 * rootWindow.uiScale)
                                        font.bold: true
                                        color: index < 3 ? rootWindow.theme.accentText : rootWindow.theme.muted
                                    }
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 32
                                    anchors.right: amountTextTopMerch.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.peer
                                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                                    color: rootWindow.theme.text
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: amountTextTopMerch
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Number(modelData.amount).toFixed(2)
                                    font.pixelSize: Math.round(14 * rootWindow.uiScale)
                                    font.bold: true
                                    color: rootWindow.theme.text
                                }
                            }
                        }
                        Text {
                            visible: rootWindow.topMerchantsData.length === 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rootWindow.txt.noRecords
                            font.pixelSize: Math.round(12 * rootWindow.uiScale)
                            color: rootWindow.theme.faint
                        }
                    }
                }
            }
        }

        Item {
            id: detailPage
            width: parent.width
            height: parent.height - 56
            visible: currentPage === "detail"

            ListView {
                id: detailList
                width: parent.width - 14
                height: parent.height
                model: billModel
                clip: true
                spacing: 1

                delegate: Rectangle {
                    width: detailList.width
                    height: 72
                    color: rootWindow.theme.card

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 12

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - detailAmountText.width - 24
                            spacing: 4
                            Text {
                                text: model.peer
                                font.pixelSize: Math.round(15 * rootWindow.uiScale)
                                color: rootWindow.theme.text
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: model.time
                                font.pixelSize: Math.round(12 * rootWindow.uiScale)
                                color: rootWindow.isDark
                                       ? rootWindow.theme.muted
                                       : rootWindow.theme.faint
                            }
                        }
                        Text {
                            id: detailAmountText
                            anchors.verticalCenter: parent.verticalCenter
                            text: (model.direction === "收入" ? "+" : "-") + Number(model.amount).toFixed(2)
                            font.pixelSize: Math.round(16 * rootWindow.uiScale)
                            font.bold: true
                            color: model.direction === "收入"
                                   ? (rootWindow.isDark ? "#68d391" : "#2e9e5b")
                                   : rootWindow.theme.text
                        }
                    }
                }
            }

            Rectangle {
                id: scrollTrack
                visible: detailList.contentHeight > detailList.height
                width: 8
                height: detailPage.height - 16
                anchors.right: parent.right
                anchors.rightMargin: 3
                anchors.verticalCenter: parent.verticalCenter
                radius: 4
                color: rootWindow.theme.grid

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var thumbH = scrollThumb.height
                        var trackH = scrollTrack.height
                        var targetY = Math.max(0, Math.min(trackH - thumbH, mouse.y - thumbH / 2))
                        var maxContent = detailList.contentHeight - detailList.height
                        if (maxContent <= 0 || trackH <= thumbH) return
                        detailList.contentY = targetY / (trackH - thumbH) * maxContent
                    }
                }

                Rectangle {
                    id: scrollThumb
                    width: parent.width
                    radius: 4
                    color: thumbArea.pressed ? rootWindow.theme.text
                         : (thumbArea.containsMouse ? rootWindow.theme.muted : rootWindow.theme.faint)
                    readonly property real ratio: detailList.height / Math.max(1, detailList.contentHeight)
                    height: Math.max(32, scrollTrack.height * ratio)

                    function updateY() {
                        var maxContent = detailList.contentHeight - detailList.height
                        var trackH = scrollTrack.height - height
                        if (maxContent <= 0 || trackH <= 0) { y = 0; return }
                        y = trackH * (detailList.contentY / maxContent)
                    }

                    Component.onCompleted: updateY()

                    Connections {
                        target: detailList
                        function onContentYChanged() {
                            if (!thumbArea.pressed) scrollThumb.updateY()
                        }
                        function onContentHeightChanged() { scrollThumb.updateY() }
                        function onHeightChanged() { scrollThumb.updateY() }
                    }

                    MouseArea {
                        id: thumbArea
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        property real pressTrackY: 0
                        property real pressThumbY: 0
                        onPressed: {
                            var p = mapToItem(scrollTrack, mouse.x, mouse.y)
                            pressTrackY = p.y
                            pressThumbY = scrollThumb.y
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            var p = mapToItem(scrollTrack, mouse.x, mouse.y)
                            var trackH = scrollTrack.height - scrollThumb.height
                            if (trackH <= 0) return
                            var maxContent = detailList.contentHeight - detailList.height
                            if (maxContent <= 0) return
                            var newThumbY = pressThumbY + (p.y - pressTrackY)
                            newThumbY = Math.max(0, Math.min(trackH, newThumbY))
                            scrollThumb.y = newThumbY
                            detailList.contentY = newThumbY / trackH * maxContent
                        }
                    }
                }
            }
        }
    }

        MouseArea {
        id: menuBackdrop
        anchors.fill: parent
        visible: billMenu.visible
        z: 99
        onClicked: billMenu.visible = false
    }

    Item {
        id: billMenu
        visible: false
        z: 100

        property real menuX: 0
        property real menuY: 0

        width: Math.max(140, billBtn.width + 40)
        height: 92
        x: menuX
        y: menuY

        onVisibleChanged: {
            if (visible) {
                var p = billBtn.mapToItem(rootWindow.contentItem, 0, 0)
                var centerX = p.x + billBtn.width / 2
                var leftX = centerX - width / 2
                menuX = Math.max(8, Math.min(leftX, rootWindow.width - width - 8))
                menuY = p.y + billBtn.height + 4
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: rootWindow.theme.card
            border.color: rootWindow.theme.border
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Rectangle {
                id: menuImportBtn
                width: parent.width
                height: 40
                radius: 8
                color: rootWindow.theme.btnBg
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
                    text: rootWindow.txt.importLabel
                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                    color: rootWindow.theme.btnText
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: menuImportBtn.pressScale = 0.92
                    onReleased: menuImportBtn.pressScale = 1.0
                    onCanceled: menuImportBtn.pressScale = 1.0
                    onClicked: {
                        billMenu.visible = false
                        fileDialog.open()
                    }
                }
            }

            Rectangle {
                id: menuHistoryBtn
                width: parent.width
                height: 40
                radius: 8
                color: rootWindow.theme.btnBg
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
                    text: rootWindow.txt.history
                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                    color: rootWindow.theme.btnText
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: menuHistoryBtn.pressScale = 0.92
                    onReleased: menuHistoryBtn.pressScale = 1.0
                    onCanceled: menuHistoryBtn.pressScale = 1.0
                    onClicked: {
                        billMenu.visible = false
                        historyPage.open()
                    }
                }
            }
        }
    }

    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        visible: billModel.importing
        z: 3000
        color: "#80000000"

        Rectangle {
            width: 160
            height: 160
            anchors.centerIn: parent
            radius: 20
            color: rootWindow.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Item {
                    width: 48
                    height: Math.round(48 * rootWindow.uiScale)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Canvas {
                        id: spinnerCanvas
                        anchors.fill: parent

                        property color ringBg: rootWindow.theme.border
                        property color ringFg: rootWindow.theme.accent

                        onRingBgChanged: requestPaint()
                        onRingFgChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width / 2
                            var cy = height / 2
                            var r = 20

                            ctx.strokeStyle = spinnerCanvas.ringBg
                            ctx.lineWidth = 4
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.stroke()

                            ctx.strokeStyle = spinnerCanvas.ringFg
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI)
                            ctx.stroke()
                        }
                    }

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: rootWindow.txt.importing
                    font.pixelSize: Math.round(13 * rootWindow.uiScale)
                    color: rootWindow.theme.text
                }
            }
        }
    }

    HistoryPage {
        id: historyPage
        anchors.fill: parent
        visible: false
        z: 98
        onToast: function(msg) {
            toastText.text = msg
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    SettingsPage {
        id: settingsPage
        anchors.fill: parent
        visible: false
        currentAccountId: accountManager.currentId
        theme: rootWindow.theme
        onLoggedOut: {
            billModel.clear()
            rootWindow.appState = "start"
            settingsPage.visible = false
        }
        onAccountDeleted: {
            billModel.clear()
            rootWindow.appState = "start"
            settingsPage.visible = false
            toastText.text = "Account deleted"
            toast.opacity = 1
            toastTimer.restart()
        }
        onToast: function(msg) {
            toastText.text = msg
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    FileDialog {
        id: fileDialog
        title: rootWindow.txt.selectFile
        fileMode: FileDialog.OpenFile
        nameFilters: [rootWindow.txt.excelFilter, rootWindow.txt.allFilter]
        onAccepted: billModel.importXlsx(selectedFile)
    }

    Connections {
        target: billModel
        function onImportDone(message) {
            toastText.text = message
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    YearMonthWheel {
        id: ymWheelMain
        width: rootWindow.width
        height: rootWindow.height
        x: 0
        y: 0
        visible: false
        year: rootWindow.monthYear
        month: rootWindow.monthMonth
        theme: rootWindow.theme
        onAccepted: {
            rootWindow.monthYear = ymWheelMain.year
            rootWindow.monthMonth = ymWheelMain.month
            visible = false
        }
        onCanceled: visible = false
    }

    YearMonthWheel {
        id: ymWheelOverlay
        width: rootWindow.width
        height: rootWindow.height
        x: 0
        y: 0
        visible: false
        theme: rootWindow.theme
        onAccepted: {
            if (rootWindow.overlayTarget === "alpha") {
                rootWindow.alphaYear = ymWheelOverlay.year
                rootWindow.alphaMonth = ymWheelOverlay.month
            } else if (rootWindow.overlayTarget === "beta") {
                rootWindow.betaYear = ymWheelOverlay.year
                rootWindow.betaMonth = ymWheelOverlay.month
            }
            visible = false
        }
        onCanceled: visible = false
    }

    YearMonthWheel {
        id: ymWheelTopMerch
        width: rootWindow.width
        height: rootWindow.height
        x: 0
        y: 0
        visible: false
        year: rootWindow.topMerchYear
        month: rootWindow.topMerchMonth
        theme: rootWindow.theme
        onAccepted: {
            rootWindow.topMerchYear = ymWheelTopMerch.year
            rootWindow.topMerchMonth = ymWheelTopMerch.month
            visible = false
        }
        onCanceled: visible = false
    }

    YearWheel {
        id: yearPicker
        width: rootWindow.width
        height: rootWindow.height
        x: 0
        y: 0
        visible: false
        year: rootWindow.selectedYear
        theme: rootWindow.theme
        onAccepted: {
            rootWindow.selectedYear = yearPicker.year
            visible = false
        }
        onCanceled: visible = false
    }

    YearWheel {
        id: yearCmpWheel
        width: rootWindow.width
        height: rootWindow.height
        x: 0
        y: 0
        visible: false
        year: rootWindow.selectedYear
        theme: rootWindow.theme
        onAccepted: {
            if (rootWindow.yearOverlayTarget === "alpha")
                rootWindow.alphaYearCmp = yearCmpWheel.year
            else if (rootWindow.yearOverlayTarget === "beta")
                rootWindow.betaYearCmp = yearCmpWheel.year
            visible = false
        }
        onCanceled: visible = false
    }

    Item {
        id: appExitConfirm
        anchors.fill: parent
        visible: false
        z: 1000

        Rectangle {
            anchors.fill: parent
            color: "#59000000"
            MouseArea {
                anchors.fill: parent
                onClicked: appExitConfirm.visible = false
            }
        }

        Rectangle {
            id: exitDialogCard
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 170
            anchors.centerIn: parent
            radius: 16
            color: rootWindow.theme.card

            property real flashScale: 1.0
            scale: flashScale

            SequentialAnimation {
                id: appExitFlash
                NumberAnimation { target: exitDialogCard; property: "flashScale"; to: 0.94; duration: 80 }
                NumberAnimation { target: exitDialogCard; property: "flashScale"; to: 1.06; duration: 100 }
                NumberAnimation { target: exitDialogCard; property: "flashScale"; to: 1.0; duration: 120 }
            }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: rootWindow.txt.confirmExit
                    font.pixelSize: Math.round(16 * rootWindow.uiScale)
                    font.bold: true
                    color: rootWindow.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        id: appExitCancelBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: rootWindow.theme.btnBg
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: rootWindow.txt.cancel
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            color: rootWindow.theme.muted
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: appExitCancelBtn.pressScale = 0.88
                            onReleased: appExitCancelBtn.pressScale = 1.0
                            onCanceled: appExitCancelBtn.pressScale = 1.0
                            onClicked: appExitConfirm.visible = false
                        }
                    }

                    Rectangle {
                        id: appExitConfirmBtn
                        width: 100
                        height: 40
                        radius: 20
                        color: rootWindow.theme.danger
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: rootWindow.txt.exitAction
                            font.pixelSize: Math.round(14 * rootWindow.uiScale)
                            font.bold: true
                            color: "#ffffff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: appExitConfirmBtn.pressScale = 0.88
                            onReleased: appExitConfirmBtn.pressScale = 1.0
                            onCanceled: appExitConfirmBtn.pressScale = 1.0
                            onClicked: {
                                appExitConfirmBtn.pressScale = 1.0
                                rootWindow.allowClose = true
                                rootWindow.close()
                            }
                        }
                    }
                }
            }
        }
    }

        Timer {
        id: importExitTimer
        interval: 8000
        onTriggered: {
            if (billModel.importing)
                importExitDialog.visible = true
        }
    }

    Item {
        id: importExitDialog
        anchors.fill: parent
        visible: false
        z: 4000

        Rectangle {
            anchors.fill: parent
            color: "#99000000"
            MouseArea {
                anchors.fill: parent
            }
        }

        Rectangle {
            width: Math.min(Math.round(280 * rootWindow.uiScale), parent.width - 40)
            height: 180
            anchors.centerIn: parent
            radius: 16
            color: rootWindow.theme.card

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: rootWindow.txt.importStillRunning
                    font.pixelSize: Math.round(15 * rootWindow.uiScale)
                    font.bold: true
                    color: rootWindow.theme.text
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    Rectangle {
                        id: keepWaitingBtn
                        width: 120
                        height: 40
                        radius: 20
                        color: rootWindow.theme.btnBg
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: rootWindow.txt.keepWaiting
                            font.pixelSize: Math.round(13 * rootWindow.uiScale)
                            color: rootWindow.theme.btnText
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: keepWaitingBtn.pressScale = 0.88
                            onReleased: keepWaitingBtn.pressScale = 1.0
                            onCanceled: keepWaitingBtn.pressScale = 1.0
                            onClicked: {
                                importExitDialog.visible = false
                                if (billModel.importing)
                                    importExitTimer.restart()
                            }
                        }
                    }

                    Rectangle {
                        id: forceExitBtn
                        width: 120
                        height: 40
                        radius: 20
                        color: rootWindow.theme.danger
                        property real pressScale: 1.0
                        scale: pressScale
                        Behavior on pressScale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: rootWindow.txt.forceExit
                            font.pixelSize: Math.round(13 * rootWindow.uiScale)
                            font.bold: true
                            color: "#ffffff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: forceExitBtn.pressScale = 0.88
                            onReleased: forceExitBtn.pressScale = 1.0
                            onCanceled: forceExitBtn.pressScale = 1.0
                            onClicked: {
                                importExitDialog.visible = false
                                rootWindow.pendingExitAfterImport = true
                                billModel.cancelImport()
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: billModel
        function onImportingChanged() {
            if (!billModel.importing) {
                importExitTimer.stop()
                if (rootWindow.pendingExitAfterImport) {
                    rootWindow.pendingExitAfterImport = false
                    rootWindow.allowClose = true
                    rootWindow.close()
                }
            }
        }
        function onImportDone(message) {
            toastText.text = message
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        width: toastText.implicitWidth + 32
        height: 40
        radius: 20
        color: rootWindow.theme.accent
        opacity: 0
        visible: opacity > 0.01
        z: 2000

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Text {
            id: toastText
            anchors.centerIn: parent
            color: rootWindow.theme.accentText
            font.pixelSize: Math.round(13 * rootWindow.uiScale)
        }
    }

    Timer {
        id: toastTimer
        interval: 2500
        onTriggered: toast.opacity = 0
    }
}


