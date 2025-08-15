import QtQuick

Canvas {
    id: canvas

    // 引用外部数据
    property var chartBase: null

    function drawBackground(ctx) {
        ctx.fillStyle = "#2b2b2b";
        ctx.fillRect(0, 0, width, height);
    }

    function drawGrid(ctx) {
        if (!chartBase)
            return ;

        ctx.strokeStyle = "#444444";
        ctx.lineWidth = 1;
        ctx.setLineDash([2, 2]);
        var visibleData = chartBase.getVisibleData();
        if (visibleData.length === 0)
            return ;

        // 垂直网格线
        var xStep = chartBase.chartWidth / Math.max(1, visibleData.length - 1);
        for (var i = 0; i <= visibleData.length; i++) {
            var x = chartBase.leftMargin + i * xStep;
            ctx.beginPath();
            ctx.moveTo(x, chartBase.topMargin);
            ctx.lineTo(x, chartBase.topMargin + chartBase.chartHeight);
            ctx.stroke();
        }
        // 水平网格线
        var gridLines = 5;
        for (var j = 0; j <= gridLines; j++) {
            var y = chartBase.topMargin + j * (chartBase.chartHeight / gridLines);
            ctx.beginPath();
            ctx.moveTo(chartBase.leftMargin, y);
            ctx.lineTo(chartBase.leftMargin + chartBase.chartWidth, y);
            ctx.stroke();
        }
        ctx.setLineDash([]);
    }

    function drawKLines(ctx) {
        if (!chartBase)
            return ;

        var visibleData = chartBase.getVisibleData();
        if (visibleData.length === 0)
            return ;

        var candleWidth = chartBase.chartWidth / visibleData.length * 0.6;
        var candleSpacing = chartBase.chartWidth / visibleData.length;
        for (var i = 0; i < visibleData.length; i++) {
            var kline = visibleData[i];
            var x = chartBase.leftMargin + i * candleSpacing + candleSpacing * 0.2;
            var highY = priceToY(kline.high);
            var lowY = priceToY(kline.low);
            var openY = priceToY(kline.open);
            var closeY = priceToY(kline.close);
            var isRising = kline.close >= kline.open;
            var color = isRising ? "#FF0000" : "#00FF00";
            // 绘制影线
            ctx.strokeStyle = color;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(x + candleWidth / 2, highY);
            ctx.lineTo(x + candleWidth / 2, lowY);
            ctx.stroke();
            // 绘制实体
            var bodyHeight = Math.abs(closeY - openY);
            var bodyY = Math.min(openY, closeY);
            if (bodyHeight < 1)
                bodyHeight = 1;

            ctx.fillStyle = color;
            ctx.fillRect(x, bodyY, candleWidth, bodyHeight);
            ctx.strokeStyle = color;
            ctx.lineWidth = 1;
            ctx.strokeRect(x, bodyY, candleWidth, bodyHeight);
        }
    }

    function drawAxes(ctx) {
        if (!chartBase)
            return ;

        ctx.strokeStyle = "#FFFFFF";
        ctx.fillStyle = "#FFFFFF";
        ctx.font = "12px Arial";
        ctx.lineWidth = 1;
        ctx.setLineDash([]);
        // Y轴标签（价格）
        var priceSteps = 5;
        for (var i = 0; i <= priceSteps; i++) {
            var price = chartBase.minPrice + (chartBase.maxPrice - chartBase.minPrice) * i / priceSteps;
            var y = chartBase.topMargin + chartBase.chartHeight - i * (chartBase.chartHeight / priceSteps);
            ctx.fillText(Number(price).toFixed(2), 5, y + 4);
        }
        // X轴标签（时间）
        var visibleData = chartBase.getVisibleData();
        if (visibleData.length > 0) {
            var maxLabels = 8;
            var step = Math.max(1, Math.ceil(visibleData.length / maxLabels));
            var previousDate = "";
            for (var j = 0; j < visibleData.length; j += step) {
                var currentDate = getDateFromTime(visibleData[j].time);
                var showDate = (currentDate !== previousDate);
                var x = chartBase.leftMargin + j * (chartBase.chartWidth / visibleData.length) + (chartBase.chartWidth / visibleData.length) / 2;
                var timeStr = formatTime(visibleData[j].time, showDate);
                ctx.save();
                ctx.translate(x, height - 5);
                ctx.rotate(-Math.PI / 6);
                if (timeStr.indexOf('\n') !== -1) {
                    var lines = timeStr.split('\n');
                    ctx.fillText(lines[0], 0, -8);
                    ctx.fillText(lines[1], 0, 8);
                } else {
                    ctx.fillText(timeStr, 0, 0);
                }
                ctx.restore();
                previousDate = currentDate;
            }
            // 显示最后一个时间点
            var lastIndex = visibleData.length - 1;
            if (lastIndex % step !== 0) {
                var lastDate = getDateFromTime(visibleData[lastIndex].time);
                var showLastDate = (lastDate !== previousDate);
                var lastX = chartBase.leftMargin + lastIndex * (chartBase.chartWidth / visibleData.length) + (chartBase.chartWidth / visibleData.length) / 2;
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
        var timeParts = timeString.split(' ');
        if (timeParts.length >= 2) {
            var date = timeParts[0];
            var time = timeParts[1];
            var timeParts2 = time.split(':');
            var timeStr = "00:00";
            if (timeParts2.length >= 2)
                timeStr = timeParts2[0] + ":" + timeParts2[1];

            if (showDate) {
                var dateParts = date.split('-');
                if (dateParts.length >= 3) {
                    var shortDate = dateParts[1] + "-" + dateParts[2];
                    return shortDate + "\n" + timeStr;
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
        if (!chartBase)
            return 0;

        var ratio = (price - chartBase.minPrice) / (chartBase.maxPrice - chartBase.minPrice);
        return chartBase.topMargin + chartBase.chartHeight - ratio * chartBase.chartHeight;
    }

    function drawCrosshair(ctx) {
        if (!chartBase || !chartBase.showCrosshair || chartBase.hoveredIndex < 0)
            return ;

        ctx.strokeStyle = "#FFFF00";
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 5]);
        // 垂直线
        ctx.beginPath();
        ctx.moveTo(chartBase.mouseX, chartBase.topMargin);
        ctx.lineTo(chartBase.mouseX, chartBase.topMargin + chartBase.chartHeight);
        ctx.stroke();
        // 水平线
        ctx.beginPath();
        ctx.moveTo(chartBase.leftMargin, chartBase.mouseY);
        ctx.lineTo(chartBase.leftMargin + chartBase.chartWidth, chartBase.mouseY);
        ctx.stroke();
        ctx.setLineDash([]);
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!chartBase || chartBase.klineData.length === 0)
            return ;

        chartBase.updatePriceRange();
        drawBackground(ctx);
        drawGrid(ctx);
        drawKLines(ctx);
        drawAxes(ctx);
        drawCrosshair(ctx);
    }
}
