import QtQuick

Item {
    id: root

    property var chartData: []
    property var theme: ({})
    property bool isDark: false

    readonly property var paletteColors: [
        "#4a90e2", "#e28b4a", "#5bbf7a", "#e05c5c",
        "#8e6fd0", "#3fb6c4", "#d4a93a", "#9a9a9a"
    ]

    readonly property color leaderColor: isDark ? "#888888" : (theme.border || "#cccccc")
    readonly property color percentColor: isDark ? "#ffffff" : (theme.muted || "#666666")

    onChartDataChanged: canvas.requestPaint()
    onIsDarkChanged: canvas.requestPaint()
    onThemeChanged: canvas.requestPaint()

    function shade(hex, f) {
        var r = parseInt(hex.substr(1, 2), 16) * f
        var g = parseInt(hex.substr(3, 2), 16) * f
        var b = parseInt(hex.substr(5, 2), 16) * f
        return "rgb(" + Math.round(r) + "," + Math.round(g) + "," + Math.round(b) + ")"
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
            if (!data || data.length === 0) return

            var total = 0
            for (var i = 0; i < data.length; ++i) total += data[i].amount
            if (total <= 0) return

            var cx = width / 2
            var cy = height * 0.40
            var rx = Math.min(width * 0.24, height * 0.38)
            var ry = rx * 0.62
            var th = rx * 0.22

            var segs = []
            var a = -Math.PI / 2
            for (var i = 0; i < data.length; ++i) {
                var sweep = data[i].amount / total * Math.PI * 2
                segs.push({
                    a1: a,
                    a2: a + sweep,
                    color: root.paletteColors[i % root.paletteColors.length],
                    amount: data[i].amount
                })
                a += sweep
            }

            function pt(angle, dy) {
                return {
                    x: cx + rx * Math.cos(angle),
                    y: cy + ry * Math.sin(angle) + (dy || 0)
                }
            }

            for (var s = 0; s < segs.length; ++s) {
                var g = segs[s]
                var n = Math.max(2, Math.ceil((g.a2 - g.a1) / 0.06))
                var step = (g.a2 - g.a1) / n

                ctx.beginPath()
                var p0 = pt(g.a1, 0)
                ctx.moveTo(p0.x, p0.y)
                for (var k = 1; k <= n; ++k) {
                    var p = pt(g.a1 + step * k, 0)
                    ctx.lineTo(p.x, p.y)
                }
                var pe = pt(g.a2, th)
                ctx.lineTo(pe.x, pe.y)
                for (var k = n - 1; k >= 0; --k) {
                    var p = pt(g.a1 + step * k, th)
                    ctx.lineTo(p.x, p.y)
                }
                ctx.closePath()
                ctx.fillStyle = root.shade(g.color, 0.68)
                ctx.fill()
            }

            for (var s = 0; s < segs.length; ++s) {
                var g = segs[s]
                var n = Math.max(2, Math.ceil((g.a2 - g.a1) / 0.04))
                var step = (g.a2 - g.a1) / n

                ctx.beginPath()
                ctx.moveTo(cx, cy)
                for (var k = 0; k <= n; ++k) {
                    var p = pt(g.a1 + step * k, 0)
                    ctx.lineTo(p.x, p.y)
                }
                ctx.closePath()
                ctx.fillStyle = g.color
                ctx.fill()
            }

            ctx.font = "600 10px 'Microsoft YaHei UI', 'Microsoft YaHei', sans-serif"
            ctx.textBaseline = "middle"
            for (var s = 0; s < segs.length; ++s) {
                var g = segs[s]
                var pct = g.amount / total * 100
                if (pct < 3) continue

                var mid = (g.a1 + g.a2) / 2
                var side = Math.cos(mid) >= 0 ? 1 : -1

                var sx = cx + rx * Math.cos(mid)
                var sy = cy + ry * Math.sin(mid)
                var ex = cx + (rx + 8) * Math.cos(mid)
                var ey = cy + (ry + 8) * Math.sin(mid)
                var tx = ex + side * 12
                var ty = ey

                ctx.strokeStyle = root.leaderColor
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(sx, sy)
                ctx.lineTo(ex, ey)
                ctx.lineTo(tx, ty)
                ctx.stroke()

                ctx.textAlign = side > 0 ? "left" : "right"
                ctx.fillStyle = root.percentColor
                ctx.fillText(Math.round(pct) + "%", tx + side * 4, ty)
            }
        }
    }
}

