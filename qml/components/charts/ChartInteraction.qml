import QtQuick

MouseArea {
    id: interaction

    // 引用外部数据和画布
    property var chartBase: null
    property var canvas: null

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPositionChanged: function(mouse) {
        if (!chartBase)
            return ;

        chartBase.mouseX = mouse.x;
        chartBase.mouseY = mouse.y;
        // 处理拖拽滚动
        if (chartBase.isDragging && (mouse.buttons & Qt.LeftButton)) {
            var deltaX = mouse.x - chartBase.lastMouseX;
            var moveRatio = deltaX / chartBase.chartWidth;
            var moveCount = Math.floor(moveRatio * chartBase.visibleCount);
            if (Math.abs(moveCount) >= 1) {
                chartBase.startIndex = Math.max(0, Math.min(chartBase.klineData.length - chartBase.visibleCount, chartBase.startIndex - moveCount));
                chartBase.lastMouseX = mouse.x;
                if (canvas)
                    canvas.requestPaint();

            }
        }
        // 更新悬浮信息
        chartBase.hoveredIndex = chartBase.getKLineIndexFromX(mouse.x);
        chartBase.showCrosshair = (chartBase.hoveredIndex >= 0);
        if (canvas)
            canvas.requestPaint();

    }
    onPressed: function(mouse) {
        if (!chartBase)
            return ;

        if (mouse.button === Qt.LeftButton) {
            chartBase.isDragging = true;
            chartBase.lastMouseX = mouse.x;
        }
    }
    onReleased: function(mouse) {
        if (!chartBase)
            return ;

        if (mouse.button === Qt.LeftButton)
            chartBase.isDragging = false;

    }
    onExited: function() {
        if (!chartBase)
            return ;

        chartBase.showCrosshair = false;
        chartBase.hoveredIndex = -1;
        chartBase.isDragging = false;
        if (canvas)
            canvas.requestPaint();

    }
    onWheel: function(wheel) {
        if (!chartBase || !canvas)
            return ;

        var centerX = wheel.x;
        if (wheel.angleDelta.y > 0)
            chartBase.zoomIn(centerX);
        else if (wheel.angleDelta.y < 0)
            chartBase.zoomOut(centerX);
        canvas.requestPaint();
    }
}
