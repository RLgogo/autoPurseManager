import QtQuick

Item {
    id: root

    property var chartData: []
    property var extraSeries: []
    property int viewDays: -1
    property color lineColor: "#4a90e2"
    property real hoverX: -1
    property real offset: 0
    property var theme: ({})
    property bool isDark: false
    property string dateSuffix: ""
    property string avgText: ""
    property bool invertY: false
    property bool skipMiddleGrid: false

    property real displayMax: 10
    property real displayMin: 0
    property real displayStep: 10

    readonly property color gridColor: isDark ? "#444444" : (theme.grid || "#eeeeee")
    readonly property color axisTextColor: isDark ? "#c0c0c0" : (theme.faint || "#9a9a9a")
    readonly property color hoverLineColor: isDark ? "#8a8a8a" : (theme.border || "#bbbbbb")
    readonly property color hoverValueColor: isDark ? "#ffffff" : (theme.muted || "#555555")
    readonly property color hoverDateColor: isDark ? "#e0e0e0" : (theme.muted || "#666666")
    readonly property color endDateColor: isDark ? "#c8c8c8" : "#9a9a9a"
    readonly property color zeroLineColor: isDark ? "#888888" : "#999999"

    NumberAnimation {
        id: maxAnim
        target: root
        property: "displayMax"
        duration: 120
        easing.type: Easing.OutCubic
        onFinished: root.skipMiddleGrid = false
    }

    NumberAnimation {
        id: minAnim
        target: root
        property: "displayMin"
        duration: 120
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: snapAnim
        target: root
        property: "offset"
        duration: 420
        easing.type: Easing.OutBack
        easing.overshoot: 1.4
        onFinished: root.recomputeMax()
    }

    Timer {
        id: recomputeThrottle
        interval: 70
        repeat: false
        onTriggered: root.recomputeMax()
    }

    readonly property int totalDays: chartData.length
    readonly property int visibleDays: viewDays > 0 ? Math.min(viewDays, totalDays) : totalDays
    readonly property real maxOffset: Math.max(0, totalDays - visibleDays)

    function niceStep(ideal) {
        if (ideal <= 0) return 1
        var exp = Math.floor(Math.log(ideal) / Math.LN10)
        var base = Math.pow(10, exp)
        var cands = [1, 2, 3, 5, 10]
        for (var i = 0; i < cands.length; ++i) {
            var s = base * cands[i]
            if (s >= ideal) return s
        }
        return base * 10
    }

    function setDisplayRange(mn, mx, immediate) {
        if (Math.abs(displayMax - mx) < 0.01 && Math.abs(displayMin - mn) < 0.01) return

        var oldRange = displayMax - displayMin
        var newRange = mx - mn
        if (oldRange > 0.01 && newRange > 0.01) {
            var ratio = newRange / oldRange
            if (ratio > 5.0 || ratio < 0.2) {
                skipMiddleGrid = true
            } else if (ratio > 2.0 || ratio < 0.5) {
                immediate = true
            }
        }

        if (immediate) {
            maxAnim.stop()
            minAnim.stop()
            displayMax = mx
            displayMin = mn
            skipMiddleGrid = false
            return
        }
        maxAnim.stop()
        minAnim.stop()
        maxAnim.to = mx
        minAnim.to = mn
        maxAnim.start()
        minAnim.start()
    }

    function recomputeMax() {
        var data = root.chartData
        var extras = root.extraSeries
        if (data.length === 0 && extras.length === 0) {
            root.displayStep = 10
            root.setDisplayRange(0, 40, false)
            return
        }

        var dataMax = 0
        var dataMin = 0
        var start = Math.max(0, Math.floor(root.offset))
        var end = Math.min(data.length, Math.ceil(root.offset + root.visibleDays))
        for (var i = start; i < end; ++i) {
            if (!data[i]) continue
            if (data[i].amount > dataMax) dataMax = data[i].amount
            if (data[i].amount < dataMin) dataMin = data[i].amount
        }

        for (var s = 0; s < extras.length; ++s) {
            var arr = extras[s].data || []
            for (var j = 0; j < arr.length; ++j) {
                if (arr[j] && arr[j].amount !== -99999) {
                    if (arr[j].amount > dataMax) dataMax = arr[j].amount
                    if (arr[j].amount < dataMin) dataMin = arr[j].amount
                }
            }
        }

        if (dataMax === 0 && dataMin === 0) {
            root.displayStep = 10
            root.setDisplayRange(0, 40, false)
            return
        }

        var range = dataMax - dataMin
        if (range < 1) range = 1
        var step = niceStep(range * 1.2 / 4)
        if (step < 1) step = 1

        var niceMin = Math.floor(dataMin * 1.15 / step) * step
        var niceMax = Math.ceil(dataMax * 1.15 / step) * step
        if (niceMin > 0) niceMin = 0
        if (niceMax < 0) niceMax = 0
        if (niceMin === niceMax) niceMax = niceMin + step * 4

        root.displayStep = step
        root.setDisplayRange(niceMin, niceMax, false)
    }

    onChartDataChanged: {
        offset = Math.max(0, Math.min(maxOffset, totalDays - visibleDays))
        recomputeMax()
        setDisplayRange(displayMin, displayMax, true)
        canvas.requestPaint()
    }
    onExtraSeriesChanged: {
        recomputeMax()
        canvas.requestPaint()
    }
    onVisibleDaysChanged: {
        offset = Math.max(0, Math.min(maxOffset, offset))
        recomputeMax()
        canvas.requestPaint()
    }
    onInvertYChanged: canvas.requestPaint()
    onOffsetChanged: {
        canvas.requestPaint()
        if (mouseArea.dragging || snapAnim.running) {
            if (!recomputeThrottle.running)
                recomputeThrottle.start()
        } else {
            recomputeMax()
        }
    }
    onDisplayMaxChanged: canvas.requestPaint()
    onDisplayMinChanged: canvas.requestPaint()
    onIsDarkChanged: canvas.requestPaint()
    onThemeChanged: canvas.requestPaint()

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -42
        anchors.rightMargin: 10
        text: root.avgText
        font.pixelSize: Math.round(11 * rootWindow.uiScale)
        color: root.axisTextColor
        visible: text.length > 0
        z: 1
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var data = root.chartData
            var n = data.length
            var extras = root.extraSeries
            if (n === 0 && extras.length === 0) return

            var minV = root.displayMin
            var maxV = root.displayMax
            if (maxV <= minV) maxV = minV + 1
            var rangeV = maxV - minV

            var padL = 56, padR = 32, padT = 12, padB = 28
            var plotW = width - padL - padR
            var plotH = height - padT - padB
            var vDays = root.visibleDays
            var denom = Math.max(1, vDays - 1)

            function xFor(i) {
                return padL + plotW * (i - root.offset) / denom
            }
            function yFor(amount) {
                var frac = (amount - minV) / rangeV
                if (root.invertY) return padT + plotH * frac
                return padT + plotH * (1 - frac)
            }

            ctx.strokeStyle = root.gridColor
            ctx.lineWidth = 1
            ctx.font = "10px sans-serif"
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"
            ctx.fillStyle = root.axisTextColor

            var step = root.displayStep
            var vStart = Math.ceil(minV / step) * step
            var tickTotal = Math.floor((maxV - vStart) / step) + 1
            var tickIdx = 0
            for (var v = vStart; v <= maxV + 0.001; v += step) {
                tickIdx++
                if (root.skipMiddleGrid && tickIdx > 1 && tickIdx < tickTotal) continue

                var y = yFor(v)
                if (y < padT - 0.5 || y > padT + plotH + 0.5) continue

                ctx.beginPath()
                ctx.moveTo(padL, y)
                ctx.lineTo(padL + plotW, y)
                ctx.stroke()

                ctx.fillText(Math.round(v).toString(), padL - 6, y)
            }

            if (minV < 0 && maxV > 0) {
                var zeroY = yFor(0)
                ctx.strokeStyle = root.zeroLineColor
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.moveTo(padL, zeroY)
                ctx.lineTo(padL + plotW, zeroY)
                ctx.stroke()
            }

            ctx.textAlign = "start"
            ctx.textBaseline = "alphabetic"

            ctx.save()
            ctx.beginPath()
            ctx.rect(padL - 10, padT - 10, plotW + 20, plotH + 20)
            ctx.clip()

            for (var s = 0; s < extras.length; ++s) {
                var arr = extras[s].data
                if (!arr || arr.length === 0) continue
                var m = arr.length
                var color = extras[s].color || "#888888"
                var isDash = extras[s].dash === true

                ctx.strokeStyle = color
                ctx.lineWidth = 1.5
                if (isDash) ctx.setLineDash([6, 4])
                else ctx.setLineDash([])

                ctx.beginPath()
                var started = false
                for (var i = 0; i < m; ++i) {
                    if (!arr[i] || arr[i].amount === -99999) {
                        started = false
                        continue
                    }
                    var x = xFor(i)
                    var yv = yFor(arr[i].amount)
                    if (!started) {
                        ctx.moveTo(x, yv)
                        started = true
                    } else {
                        ctx.lineTo(x, yv)
                    }
                }
                ctx.stroke()
                ctx.setLineDash([])

                ctx.fillStyle = color
                for (var i = 0; i < m; ++i) {
                    if (!arr[i] || arr[i].amount === -99999) continue
                    ctx.beginPath()
                    ctx.arc(xFor(i), yFor(arr[i].amount), 2, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            if (n > 0) {
                ctx.strokeStyle = root.lineColor
                ctx.lineWidth = 2
                ctx.beginPath()
                for (var i = 0; i < n; ++i) {
                    if (i === 0) ctx.moveTo(xFor(i), yFor(data[i].amount))
                    else ctx.lineTo(xFor(i), yFor(data[i].amount))
                }
                ctx.stroke()

                ctx.fillStyle = root.lineColor
                for (var i = 0; i < n; ++i) {
                    ctx.beginPath()
                    ctx.arc(xFor(i), yFor(data[i].amount), 3, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            ctx.restore()

            if (n > 0 && root.hoverX < 0) {
                var firstIdx = Math.max(0, Math.ceil(root.offset))
                var lastIdx = Math.min(n - 1, Math.floor(root.offset + vDays - 1))
                if (firstIdx <= lastIdx) {
                    ctx.fillStyle = root.endDateColor
                    ctx.font = "10px sans-serif"
                    ctx.textBaseline = "alphabetic"

                    ctx.textAlign = "start"
                    ctx.fillText(data[firstIdx].date + root.dateSuffix, padL, height - 8)

                    ctx.textAlign = "right"
                    ctx.fillText(data[lastIdx].date + root.dateSuffix, padL + plotW, height - 8)
                }
            }

            if (root.hoverX >= padL && root.hoverX <= padL + plotW && n > 0) {
                var dayFloat = root.offset + (root.hoverX - padL) / plotW * denom
                var idx = Math.round(dayFloat)
                if (idx >= 0 && idx < n) {
                    var cx = xFor(idx)
                    var cy = yFor(data[idx].amount)

                    ctx.strokeStyle = root.hoverLineColor
                    ctx.lineWidth = 1
                    ctx.setLineDash([4, 3])
                    ctx.beginPath()
                    ctx.moveTo(cx, padT)
                    ctx.lineTo(cx, padT + plotH)
                    ctx.stroke()
                    ctx.setLineDash([])

                    var items = []
                    if (data[idx])
                        items.push({ color: root.lineColor, amount: data[idx].amount })

                    for (var s = 0; s < extras.length; ++s) {
                        var arr2 = extras[s].data
                        if (arr2 && idx < arr2.length && arr2[idx] && arr2[idx].amount !== -99999)
                            items.push({
                                color: extras[s].color || "#888888",
                                amount: arr2[idx].amount
                            })
                    }

                    ctx.fillStyle = root.lineColor
                    ctx.beginPath()
                    ctx.arc(cx, cy, 4, 0, Math.PI * 2)
                    ctx.fill()

                    for (var s = 0; s < extras.length; ++s) {
                        var arr2 = extras[s].data
                        if (arr2 && idx < arr2.length && arr2[idx] && arr2[idx].amount !== -99999) {
                            var ey = yFor(arr2[idx].amount)
                            ctx.fillStyle = extras[s].color || "#888888"
                            ctx.beginPath()
                            ctx.arc(cx, ey, 3.5, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }

                    ctx.font = "600 11px 'Microsoft YaHei UI', 'Microsoft YaHei', sans-serif"
                    var padX = 7, padY = 5, rowH = 15
                    var maxTW = 0
                    for (var k = 0; k < items.length; ++k) {
                        var tw = ctx.measureText("楼" + Number(items[k].amount).toFixed(2)).width
                        if (tw > maxTW) maxTW = tw
                    }
                    var boxW = maxTW + 12 + padX * 2
                    var boxH = items.length * rowH + padY * 2

                    function countPointsInRect(rx, ry, rw, rh) {
                        var cnt = 0
                        for (var i = 0; i < n; ++i) {
                            if (!data[i]) continue
                            var px = xFor(i)
                            var py = yFor(data[i].amount)
                            if (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh) cnt++
                        }
                        for (var s = 0; s < extras.length; ++s) {
                            var arr = extras[s].data
                            if (!arr) continue
                            for (var i = 0; i < arr.length; ++i) {
                                if (!arr[i] || arr[i].amount < 0) continue
                                var px = xFor(i)
                                var py = yFor(arr[i].amount)
                                if (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh) cnt++
                            }
                        }
                        return cnt
                    }

                    var gap = 14
                    var candidates = [
                        { x: cx - boxW / 2, y: cy - boxH - gap },
                        { x: cx + gap,       y: cy - boxH / 2 },
                        { x: cx - boxW - gap, y: cy - boxH / 2 },
                        { x: cx + gap,       y: cy + gap / 2 },
                        { x: cx - boxW - gap, y: cy + gap / 2 },
                        { x: cx - boxW / 2, y: cy + gap }
                    ]

                    var bestX = candidates[0].x
                    var bestY = candidates[0].y
                    var foundClean = false

                    for (var c = 0; c < candidates.length; ++c) {
                        var bx = candidates[c].x
                        var by = candidates[c].y
                        if (bx < padL) bx = padL
                        if (bx + boxW > padL + plotW) bx = padL + plotW - boxW
                        if (by < padT) by = padT
                        if (by + boxH > padT + plotH) by = padT + plotH - boxH
                        if (countPointsInRect(bx, by, boxW, boxH) === 0) {
                            bestX = bx
                            bestY = by
                            foundClean = true
                            break
                        }
                    }

                    if (!foundClean) {
                        var minColl = Infinity
                        for (var c = 0; c < candidates.length; ++c) {
                            var bx = candidates[c].x
                            var by = candidates[c].y
                            if (bx < padL) bx = padL
                            if (bx + boxW > padL + plotW) bx = padL + plotW - boxW
                            if (by < padT) by = padT
                            if (by + boxH > padT + plotH) by = padT + plotH - boxH
                            var coll = countPointsInRect(bx, by, boxW, boxH)
                            if (coll < minColl) {
                                minColl = coll
                                bestX = bx
                                bestY = by
                            }
                        }
                    }

                    function roundRectPath(x, y, w, h, r) {
                        ctx.beginPath()
                        ctx.moveTo(x + r, y)
                        ctx.lineTo(x + w - r, y)
                        ctx.quadraticCurveTo(x + w, y, x + w, y + r)
                        ctx.lineTo(x + w, y + h - r)
                        ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
                        ctx.lineTo(x + r, y + h)
                        ctx.quadraticCurveTo(x, y + h, x, y + h - r)
                        ctx.lineTo(x, y + r)
                        ctx.quadraticCurveTo(x, y, x + r, y)
                        ctx.closePath()
                    }

                    ctx.save()
                    ctx.globalAlpha = root.isDark ? 0.7 : 0.55
                    ctx.fillStyle = root.theme.card || "#ffffff"
                    roundRectPath(bestX, bestY, boxW, boxH, 6)
                    ctx.fill()
                    ctx.globalAlpha = 1
                    ctx.strokeStyle = root.theme.border || "#e0e0e0"
                    ctx.lineWidth = 1
                    roundRectPath(bestX, bestY, boxW, boxH, 6)
                    ctx.stroke()
                    ctx.restore()

                    ctx.textBaseline = "middle"
                    ctx.textAlign = "left"
                    for (var k = 0; k < items.length; ++k) {
                        var rowY = bestY + padY + k * rowH + rowH / 2
                        var text = "\u00A5" + Number(items[k].amount).toFixed(2)
                        ctx.fillStyle = items[k].color
                        ctx.fillRect(bestX + padX, rowY - 4, 8, 8)
                        ctx.fillText(text, bestX + padX + 12, rowY)
                    }

                    ctx.font = "600 11px 'Microsoft YaHei UI', 'Microsoft YaHei', sans-serif"
                    ctx.textBaseline = "top"
                    var dateText = data[idx].date + root.dateSuffix
                    var dw = ctx.measureText(dateText).width
                    if (cx - dw / 2 < padL) ctx.textAlign = "left"
                    else if (cx + dw / 2 > padL + plotW) ctx.textAlign = "right"
                    else ctx.textAlign = "center"
                    ctx.fillStyle = root.hoverDateColor
                    ctx.fillText(dateText, cx, padT + plotH + 7)
                    ctx.textAlign = "start"
                    ctx.textBaseline = "alphabetic"
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        property real dragStartMouseX: 0
        property real dragStartOffset: 0
        property bool dragging: false
        property bool pendingDrag: false

        onPressed: function(mouse) {
            dragStartMouseX = mouse.x
            dragStartOffset = root.offset
            dragging = false
            pendingDrag = true
            root.hoverX = mouse.x
            snapAnim.stop()
            recomputeThrottle.stop()
            canvas.requestPaint()
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                root.hoverX = mouse.x
                canvas.requestPaint()
                return
            }
            var dx = Math.abs(mouse.x - dragStartMouseX)
            if (pendingDrag && dx > 12) {
                pendingDrag = false
                dragging = true
                root.hoverX = -1
            }
            if (dragging) {
                var plotW = width - 56 - 32
                var denom = Math.max(1, root.visibleDays - 1)
                var daysPerPx = denom / Math.max(1, plotW)
                var moveDx = mouse.x - dragStartMouseX
                var rawOffset = dragStartOffset - moveDx * daysPerPx
                var maxOff = root.maxOffset
                if (rawOffset < 0)
                    rawOffset = rawOffset * 0.35
                else if (rawOffset > maxOff)
                    rawOffset = maxOff + (rawOffset - maxOff) * 0.35
                root.offset = rawOffset
            } else {
                root.hoverX = mouse.x
                canvas.requestPaint()
            }
        }

        onReleased: function(mouse) {
            if (dragging) {
                var target = Math.max(0, Math.min(root.maxOffset, root.offset))
                if (Math.abs(root.offset - target) > 0.005) {
                    snapAnim.to = target
                    snapAnim.start()
                } else {
                    recomputeMax()
                }
                root.hoverX = -1
            } else {
                root.hoverX = mouse.x
            }
            dragging = false
            pendingDrag = false
            canvas.requestPaint()
        }

        onCanceled: {
            dragging = false
            pendingDrag = false
            root.hoverX = -1
            recomputeThrottle.stop()
            canvas.requestPaint()
        }

        onExited: {
            if (!dragging && !pressed) {
                root.hoverX = -1
                canvas.requestPaint()
            }
        }

        onWheel: function(wheel) {
            if (root.maxOffset <= 0) return
            var dir = wheel.angleDelta.y > 0 ? -1 : 1
            var base = Math.round(root.offset)
            var target = Math.max(0, Math.min(root.maxOffset, base + dir))
            snapAnim.stop()
            snapAnim.to = target
            snapAnim.start()
        }
    }
}

