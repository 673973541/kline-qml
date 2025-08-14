import KLineModule
import QtQuick

Item {
    id: root

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
    property real minZoom: 0.1
    property real maxZoom: 10
    property int startIndex: 0
    property int visibleCount: 50
    property int maxVisibleCount: 200
    // 拖拽相关属性
    property bool isDragging: false
    property real lastMouseX: 0

    // 将函数移到root级别以便MouseArea访问
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
        zoomFactor = Math.min(maxZoom, zoomFactor * 1.2);
        if (zoomFactor !== oldZoom) {
            updateVisibleCount();
            adjustScrollPosition(centerX, oldZoom);
            canvas.requestPaint();
        }
    }

    function zoomOut(centerX) {
        var oldZoom = zoomFactor;
        zoomFactor = Math.max(minZoom, zoomFactor / 1.2);
        if (zoomFactor !== oldZoom) {
            updateVisibleCount();
            adjustScrollPosition(centerX, oldZoom);
            canvas.requestPaint();
        }
    }

    function updateVisibleCount() {
        visibleCount = Math.min(maxVisibleCount, Math.max(10, Math.floor(50 / zoomFactor)));
    }

    function adjustScrollPosition(centerX, oldZoom) {
        if (klineData.length === 0)
            return ;

        // 计算缩放中心点对应的数据索引
        var relativeX = (centerX - leftMargin) / chartWidth;
        var centerIndex = startIndex + relativeX * (50 / oldZoom);
        // 调整startIndex使得缩放中心保持相对位置
        var newCenterIndex = startIndex + relativeX * visibleCount;
        var offset = centerIndex - newCenterIndex;
        startIndex = Math.max(0, Math.min(startIndex + Math.floor(offset), klineData.length - visibleCount));
    }

    function scrollLeft() {
        startIndex = Math.max(0, startIndex - Math.max(1, Math.floor(visibleCount * 0.1)));
        canvas.requestPaint();
    }

    function scrollRight() {
        startIndex = Math.min(klineData.length - visibleCount, startIndex + Math.max(1, Math.floor(visibleCount * 0.1)));
        canvas.requestPaint();
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
        // 添加一些边距
        var range = maxPrice - minPrice;
        if (range > 0) {
            minPrice -= range * 0.1;
            maxPrice += range * 0.1;
        }
    }

    Component.onCompleted: {
        console.log("Canvas K线图: csvFile =", csvFile);
        if (csvFile)
            dataProvider.loadData();

    }

    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"

        // 主绘制画布
        Canvas {
            id: canvas

            function drawBackground(ctx) {
                ctx.fillStyle = "#2b2b2b";
                ctx.fillRect(0, 0, width, height);
            }

            function drawGrid(ctx) {
                ctx.strokeStyle = "#444444";
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 2]);
                var visibleData = root.getVisibleData();
                if (visibleData.length === 0)
                    return ;

                // 垂直网格线
                var xStep = root.chartWidth / Math.max(1, visibleData.length - 1);
                for (var i = 0; i <= visibleData.length; i++) {
                    var x = root.leftMargin + i * xStep;
                    ctx.beginPath();
                    ctx.moveTo(x, root.topMargin);
                    ctx.lineTo(x, root.topMargin + root.chartHeight);
                    ctx.stroke();
                }
                // 水平网格线
                var gridLines = 5;
                for (var j = 0; j <= gridLines; j++) {
                    var y = root.topMargin + j * (root.chartHeight / gridLines);
                    ctx.beginPath();
                    ctx.moveTo(root.leftMargin, y);
                    ctx.lineTo(root.leftMargin + root.chartWidth, y);
                    ctx.stroke();
                }
                ctx.setLineDash([]);
            }

            function drawKLines(ctx) {
                var visibleData = root.getVisibleData();
                if (visibleData.length === 0)
                    return ;

                var candleWidth = root.chartWidth / visibleData.length * 0.6;
                var candleSpacing = root.chartWidth / visibleData.length;
                for (var i = 0; i < visibleData.length; i++) {
                    var kline = visibleData[i];
                    var x = root.leftMargin + i * candleSpacing + candleSpacing * 0.2;
                    // 转换价格到像素坐标
                    var highY = priceToY(kline.high);
                    var lowY = priceToY(kline.low);
                    var openY = priceToY(kline.open);
                    var closeY = priceToY(kline.close);
                    var isRising = kline.close >= kline.open;
                    var color = isRising ? "#FF0000" : "#00FF00"; // 涨红跌绿
                    // 绘制影线（细线）
                    ctx.strokeStyle = color;
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(x + candleWidth / 2, highY);
                    ctx.lineTo(x + candleWidth / 2, lowY);
                    ctx.stroke();
                    // 绘制实体（矩形）
                    var bodyHeight = Math.abs(closeY - openY);
                    var bodyY = Math.min(openY, closeY);
                    if (bodyHeight < 1)
                        bodyHeight = 1;

                    // 最小高度
                    ctx.fillStyle = color;
                    ctx.fillRect(x, bodyY, candleWidth, bodyHeight);
                    // 绘制边框
                    ctx.strokeStyle = color;
                    ctx.lineWidth = 1;
                    ctx.strokeRect(x, bodyY, candleWidth, bodyHeight);
                }
            }

            function drawAxes(ctx) {
                ctx.strokeStyle = "#FFFFFF";
                ctx.fillStyle = "#FFFFFF";
                ctx.font = "12px Arial";
                ctx.lineWidth = 1;
                ctx.setLineDash([]);
                // Y轴标签（价格）
                var priceSteps = 5;
                for (var i = 0; i <= priceSteps; i++) {
                    var price = root.minPrice + (root.maxPrice - root.minPrice) * i / priceSteps;
                    var y = root.topMargin + root.chartHeight - i * (root.chartHeight / priceSteps);
                    ctx.fillText(price.toFixed(2), 5, y + 4);
                }
                // X轴标签（时间）- 根据可见K线数量自动调整显示间隔
                var visibleData = root.getVisibleData();
                if (visibleData.length > 0) {
                    var maxLabels = 8; // 最多显示8个时间标签
                    var step = Math.max(1, Math.ceil(visibleData.length / maxLabels));
                    var previousDate = "";
                    for (var j = 0; j < visibleData.length; j += step) {
                        var currentDate = getDateFromTime(visibleData[j].time);
                        var showDate = (currentDate !== previousDate); // 日期变化时显示日期
                        var x = root.leftMargin + j * (root.chartWidth / visibleData.length) + (root.chartWidth / visibleData.length) / 2;
                        var timeStr = formatTime(visibleData[j].time, showDate);
                        // 调整文字位置，避免重叠
                        ctx.save();
                        ctx.translate(x, height - 5);
                        ctx.rotate(-Math.PI / 6); // 倾斜30度
                        // 如果包含换行符，需要分行绘制
                        if (timeStr.indexOf('\n') !== -1) {
                            var lines = timeStr.split('\n');
                            ctx.fillText(lines[0], 0, -8); // 日期
                            ctx.fillText(lines[1], 0, 8); // 时间
                        } else {
                            ctx.fillText(timeStr, 0, 0);
                        }
                        ctx.restore();
                        previousDate = currentDate;
                    }
                    // 如果最后一个标签没有显示，显示最后一个时间点
                    var lastIndex = visibleData.length - 1;
                    if (lastIndex % step !== 0) {
                        var lastDate = getDateFromTime(visibleData[lastIndex].time);
                        var showLastDate = (lastDate !== previousDate);
                        var lastX = root.leftMargin + lastIndex * (root.chartWidth / visibleData.length) + (root.chartWidth / visibleData.length) / 2;
                        var lastTimeStr = formatTime(visibleData[lastIndex].time, showLastDate);
                        ctx.save();
                        ctx.translate(lastX, height - 5);
                        ctx.rotate(-Math.PI / 6);
                        if (lastTimeStr.indexOf('\n') !== -1) {
                            var lastLines = lastTimeStr.split('\n');
                            ctx.fillText(lastLines[0], 0, -8);
                            ctx.fillText(lastLines[1], 0, 8);
                        } else {
                            ctx.fillText(lastTimeStr, 0, 0);
                        }
                        ctx.restore();
                    }
                }
            }

            function formatTime(timeString, showDate) {
                // 解析时间字符串 "2025-08-14 11:26:50"
                var timeParts = timeString.split(' ');
                if (timeParts.length >= 2) {
                    var date = timeParts[0]; // "2025-08-14"
                    var time = timeParts[1]; // "11:26:50"
                    var timeParts2 = time.split(':');
                    var timeStr = "00:00";
                    if (timeParts2.length >= 2)
                        timeStr = timeParts2[0] + ":" + timeParts2[1];

                    // "11:26"
                    if (showDate) {
                        var dateParts = date.split('-');
                        if (dateParts.length >= 3) {
                            var shortDate = dateParts[1] + "-" + dateParts[2]; // "08-14"
                            return shortDate + "\n" + timeStr; // "08-14\n11:26"
                        }
                    }
                    return timeStr;
                }
                return "00:00";
            }

            function getDateFromTime(timeString) {
                var timeParts = timeString.split(' ');
                return timeParts.length > 0 ? timeParts[0] : "";
            }

            function priceToY(price) {
                var ratio = (price - root.minPrice) / (root.maxPrice - root.minPrice);
                return root.topMargin + root.chartHeight - ratio * root.chartHeight;
            }

            function drawCrosshair(ctx) {
                if (!root.showCrosshair || root.hoveredIndex < 0)
                    return ;

                ctx.strokeStyle = "#FFFF00";
                ctx.lineWidth = 1;
                ctx.setLineDash([5, 5]);
                // 垂直线
                ctx.beginPath();
                ctx.moveTo(root.mouseX, root.topMargin);
                ctx.lineTo(root.mouseX, root.topMargin + root.chartHeight);
                ctx.stroke();
                // 水平线
                ctx.beginPath();
                ctx.moveTo(root.leftMargin, root.mouseY);
                ctx.lineTo(root.leftMargin + root.chartWidth, root.mouseY);
                ctx.stroke();
                ctx.setLineDash([]);
            }

            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (root.klineData.length === 0)
                    return ;

                // 根据可见数据重新计算价格范围
                root.updatePriceRange();
                drawBackground(ctx);
                drawGrid(ctx);
                drawKLines(ctx);
                drawAxes(ctx);
                drawCrosshair(ctx);
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPositionChanged: function(mouse) {
                    root.mouseX = mouse.x;
                    root.mouseY = mouse.y;
                    // 处理拖拽滚动
                    if (root.isDragging && (mouse.buttons & Qt.LeftButton)) {
                        var deltaX = mouse.x - root.lastMouseX;
                        var moveRatio = deltaX / root.chartWidth;
                        var moveCount = Math.floor(moveRatio * root.visibleCount);
                        if (Math.abs(moveCount) >= 1) {
                            root.startIndex = Math.max(0, Math.min(root.klineData.length - root.visibleCount, root.startIndex - moveCount));
                            root.lastMouseX = mouse.x;
                            canvas.requestPaint();
                        }
                    }
                    // 更新悬浮信息
                    root.hoveredIndex = root.getKLineIndexFromX(mouse.x);
                    root.showCrosshair = (root.hoveredIndex >= 0);
                    canvas.requestPaint();
                }
                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        root.isDragging = true;
                        root.lastMouseX = mouse.x;
                    }
                }
                onReleased: function(mouse) {
                    if (mouse.button === Qt.LeftButton)
                        root.isDragging = false;

                }
                onExited: function() {
                    root.showCrosshair = false;
                    root.hoveredIndex = -1;
                    root.isDragging = false;
                    canvas.requestPaint();
                }
                onWheel: function(wheel) {
                    var centerX = wheel.x;
                    if (wheel.angleDelta.y > 0)
                        root.zoomIn(centerX);
                    else if (wheel.angleDelta.y < 0)
                        root.zoomOut(centerX);
                }
            }

        }

        // 标题
        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 5
            text: "K线图表 (Canvas绘制)"
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }

        // K线详细信息显示
        Rectangle {
            id: tooltip

            visible: root.showCrosshair && root.hoveredIndex >= 0
            x: Math.min(root.mouseX + 10, parent.width - width - 10)
            y: Math.max(10, root.mouseY - height - 10)
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
                    text: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? "时间: " + root.klineData[root.hoveredIndex].time : ""
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? "开盘: " + root.klineData[root.hoveredIndex].open.toFixed(2) : ""
                    color: "white"
                    font.pixelSize: 10
                }

                Text {
                    text: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? "最高: " + root.klineData[root.hoveredIndex].high.toFixed(2) : ""
                    color: "#FF6666"
                    font.pixelSize: 10
                }

                Text {
                    text: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? "最低: " + root.klineData[root.hoveredIndex].low.toFixed(2) : ""
                    color: "#66FF66"
                    font.pixelSize: 10
                }

                Text {
                    property bool isRising: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length && root.klineData[root.hoveredIndex].close >= root.klineData[root.hoveredIndex].open

                    text: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? "收盘: " + root.klineData[root.hoveredIndex].close.toFixed(2) : ""
                    color: isRising ? "#FF0000" : "#00FF00"
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    property real change: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length ? root.klineData[root.hoveredIndex].close - root.klineData[root.hoveredIndex].open : 0
                    property real changePercent: root.hoveredIndex >= 0 && root.hoveredIndex < root.klineData.length && root.klineData[root.hoveredIndex].open > 0 ? (change / root.klineData[root.hoveredIndex].open * 100) : 0

                    text: "涨跌: " + (change >= 0 ? "+" : "") + change.toFixed(2) + " (" + (changePercent >= 0 ? "+" : "") + changePercent.toFixed(2) + "%)"
                    color: change >= 0 ? "#FF0000" : "#00FF00"
                    font.pixelSize: 10
                }

            }

        }

    }

    // 数据提供器
    KLineDataProvider {
        id: dataProvider

        csvFile: root.csvFile
        onDataLoaded: {
            console.log("Canvas K线图: 数据加载完成, 共", data.length, "条数据");
            var tempData = [];
            for (var i = 0; i < data.length; i++) {
                var row = data[i];
                if (row.length >= 5) {
                    var kline = {
                        "time": row[0],
                        "open": parseFloat(row[1]),
                        "high": parseFloat(row[2]),
                        "low": parseFloat(row[3]),
                        "close": parseFloat(row[4])
                    };
                    tempData.push(kline);
                }
            }
            root.klineData = tempData;
            // 初始化显示参数
            root.startIndex = Math.max(0, tempData.length - root.visibleCount);
            root.updateVisibleCount();
            root.updatePriceRange();
            console.log("Canvas K线图: 总数据量", root.klineData.length, "条，可见数据量", root.visibleCount, "条");
            console.log("Canvas K线图: 起始索引", root.startIndex, "价格范围", root.minPrice.toFixed(2), "到", root.maxPrice.toFixed(2));
            // 触发重绘
            canvas.requestPaint();
        }
    }

}
