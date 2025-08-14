import QtQuick

Item {
    // console.log("zoomFactor=", zoomFactor.toFixed(3), "theoretical=", theoreticalCount, "changed:", oldVisibleCount, "→", visibleCount);

    id: root

    // 基础数据属性
    property string csvFile: ""
    property var klineData: []
    property real minPrice: 0
    property real maxPrice: 0
    // 绘制区域边距
    property real leftMargin: 60
    property real rightMargin: 20
    property real topMargin: 20
    property real bottomMargin: 40
    // 计算绘制区域
    property real chartWidth: width - leftMargin - rightMargin
    property real chartHeight: height - topMargin - bottomMargin
    // 鼠标悬浮相关属性
    property int hoveredIndex: -1
    property bool showCrosshair: false
    property real mouseX: 0
    property real mouseY: 0
    // 缩放和滚动相关属性
    property real zoomFactor: 1
    property real minZoom: 0.05 // 允许更小的缩放值，看到更多K线
    property real maxZoom: 10
    property int startIndex: 0
    property int visibleCount: 50
    property int baseVisibleCount: 50 // 基础可见数量
    property int maxVisibleCount: 100 // 进一步降低最大可见数量
    // 拖拽相关属性
    property bool isDragging: false
    property real lastMouseX: 0

    // 工具函数
    function getKLineIndexFromX(x) {
        if (getVisibleData().length === 0)
            return -1;

        var chartX = x - leftMargin;
        if (chartX < 0 || chartX > chartWidth)
            return -1;

        var visibleData = getVisibleData();
        var candleSpacing = chartWidth / visibleData.length;
        var index = Math.floor(chartX / candleSpacing);
        var actualIndex = startIndex + Math.max(0, Math.min(index, visibleData.length - 1));
        return Math.max(0, Math.min(actualIndex, klineData.length - 1));
    }

    function getVisibleData() {
        if (klineData.length === 0)
            return [];

        var endIndex = Math.min(startIndex + visibleCount, klineData.length);
        return klineData.slice(startIndex, endIndex);
    }

    function zoomIn(centerX) {
        var oldZoom = zoomFactor;
        var newZoom = Math.min(maxZoom, zoomFactor * 1.2);
        if (Math.abs(newZoom - oldZoom) > 0.001) {
            zoomFactor = newZoom;
            updateVisibleCount();
            adjustScrollPosition(centerX, oldZoom);
        }
    }

    function zoomOut(centerX) {
        var oldZoom = zoomFactor;
        var newZoom = Math.max(minZoom, zoomFactor / 1.2);
        if (Math.abs(newZoom - oldZoom) > 0.001) {
            zoomFactor = newZoom;
            updateVisibleCount();
            adjustScrollPosition(centerX, oldZoom);
        }
    }

    function updateVisibleCount() {
        var oldVisibleCount = visibleCount;
        // 使用更合理的缩放计算：确保在任何缩放级别都有变化
        var theoreticalCount;
        if (zoomFactor <= 1)
            theoreticalCount = Math.floor(baseVisibleCount + (1 - zoomFactor) * 150);
        else
            theoreticalCount = Math.floor(baseVisibleCount / zoomFactor);
        // 设置合理的边界，允许更小的可见数量
        var minCount = 5;
        // 降低最小值，允许看到更少的K线
        var maxCount = Math.min(200, klineData.length);
        // 大幅提高上限，支持更多K线
        visibleCount = Math.max(minCount, Math.min(maxCount, theoreticalCount));
    }

    function adjustScrollPosition(centerX, oldZoom) {
        if (klineData.length === 0 || chartWidth <= 0 || oldZoom <= 0)
            return ;

        // 计算缩放中心相对位置 (0-1)
        var relativeX = Math.max(0, Math.min(1, (centerX - leftMargin) / chartWidth));
        // 计算旧的可见数据量（与updateVisibleCount逻辑保持一致）
        var oldTheoreticalCount;
        if (oldZoom <= 1)
            oldTheoreticalCount = Math.floor(baseVisibleCount + (1 - oldZoom) * 150);
        else
            oldTheoreticalCount = Math.floor(baseVisibleCount / oldZoom);
        var oldVisibleCount = Math.max(5, Math.min(200, oldTheoreticalCount));
        // 计算缩放中心对应的数据索引
        var centerDataIndex = startIndex + relativeX * oldVisibleCount;
        // 调整startIndex使缩放中心保持相对位置
        var newStartIndex = centerDataIndex - relativeX * visibleCount;
        // 确保索引在有效范围内
        startIndex = Math.max(0, Math.min(Math.floor(newStartIndex), klineData.length - visibleCount));
    }

    function scrollLeft() {
        startIndex = Math.max(0, startIndex - Math.max(1, Math.floor(visibleCount * 0.1)));
    }

    function scrollRight() {
        startIndex = Math.min(klineData.length - visibleCount, startIndex + Math.max(1, Math.floor(visibleCount * 0.1)));
    }

    function updatePriceRange() {
        var visibleData = getVisibleData();
        if (visibleData.length === 0)
            return ;

        minPrice = Number.MAX_VALUE;
        maxPrice = Number.MIN_VALUE;
        for (var i = 0; i < visibleData.length; i++) {
            var kline = visibleData[i];
            minPrice = Math.min(minPrice, kline.low);
            maxPrice = Math.max(maxPrice, kline.high);
        }
        var range = maxPrice - minPrice;
        if (range > 0) {
            minPrice -= range * 0.1;
            maxPrice += range * 0.1;
        }
    }

}
