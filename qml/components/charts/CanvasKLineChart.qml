import QtQuick

Item {
    id: root

    // 对外暴露的属性 - 只接收K线数据
    property var klineData: []
    property string title: "K线图表 (Canvas绘制)"

    // 监听数据变化
    onKlineDataChanged: {
        if (klineData && klineData.length > 0) {
            // 初始化显示参数
            chartBase.startIndex = Math.max(0, klineData.length - chartBase.visibleCount);
            chartBase.updateVisibleCount();
            chartBase.updatePriceRange();
            // 触发重绘
            canvas.requestPaint();
        }
    }

    // 基础数据和功能组件
    ChartBase {
        id: chartBase

        anchors.fill: parent
        klineData: root.klineData
    }

    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"

        // Canvas绘制组件
        KLineCanvas {
            id: canvas

            anchors.fill: parent
            chartBase: chartBase
        }

        // 交互处理组件
        ChartInteraction {
            id: interaction

            chartBase: chartBase
            canvas: canvas
        }

        // 标题
        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 5
            text: root.title
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }

        // 工具提示组件
        ChartTooltip {
            id: tooltip

            chartBase: chartBase
        }

    }

    // 监听chartBase的数据变化
    Connections {
        function onKlineDataChanged() {
            if (chartBase.klineData && chartBase.klineData.length > 0) {
                // 初始化显示参数
                chartBase.startIndex = Math.max(0, chartBase.klineData.length - chartBase.visibleCount);
                chartBase.updateVisibleCount();
                chartBase.updatePriceRange();
                // 触发重绘
                canvas.requestPaint();
            }
        }

        target: chartBase
    }

}
