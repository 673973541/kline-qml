import QtQuick

Rectangle {
    id: tooltip

    // 引用外部数据
    property var chartBase: null

    visible: chartBase && chartBase.showCrosshair && chartBase.hoveredIndex >= 0
    x: chartBase ? Math.min(chartBase.mouseX + 10, parent.width - width - 10) : 0
    y: chartBase ? Math.max(10, chartBase.mouseY - height - 10) : 0
    width: 180
    height: 120
    color: "#333333"
    border.color: "#666666"
    border.width: 1
    radius: 5

    Column {
        anchors.margins: 8
        anchors.fill: parent
        spacing: 4

        Text {
            text: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? "时间: " + chartBase.klineData[chartBase.hoveredIndex].time : ""
            color: "white"
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            text: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? "开盘: " + chartBase.klineData[chartBase.hoveredIndex].open.toFixed(2) : ""
            color: "white"
            font.pixelSize: 10
        }

        Text {
            text: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? "最高: " + chartBase.klineData[chartBase.hoveredIndex].high.toFixed(2) : ""
            color: "#FF6666"
            font.pixelSize: 10
        }

        Text {
            text: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? "最低: " + chartBase.klineData[chartBase.hoveredIndex].low.toFixed(2) : ""
            color: "#66FF66"
            font.pixelSize: 10
        }

        Text {
            property bool isRising: chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length && chartBase.klineData[chartBase.hoveredIndex].close >= chartBase.klineData[chartBase.hoveredIndex].open

            text: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? "收盘: " + chartBase.klineData[chartBase.hoveredIndex].close.toFixed(2) : ""
            color: isRising ? "#FF0000" : "#00FF00"
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            property real change: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length) ? chartBase.klineData[chartBase.hoveredIndex].close - chartBase.klineData[chartBase.hoveredIndex].open : 0
            property real changePercent: (chartBase && chartBase.hoveredIndex >= 0 && chartBase.hoveredIndex < chartBase.klineData.length && chartBase.klineData[chartBase.hoveredIndex].open > 0) ? (change / chartBase.klineData[chartBase.hoveredIndex].open * 100) : 0

            text: "涨跌: " + (change >= 0 ? "+" : "") + change.toFixed(2) + " (" + (changePercent >= 0 ? "+" : "") + changePercent.toFixed(2) + "%)"
            color: change >= 0 ? "#FF0000" : "#00FF00"
            font.pixelSize: 10
        }

    }

}
