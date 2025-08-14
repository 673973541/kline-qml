import QtQuick
import KLineModule

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
    
    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"
        
        // 主绘制画布
        Canvas {
            id: canvas
            anchors.fill: parent
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                if (root.klineData.length === 0) return;
                
                drawBackground(ctx);
                drawGrid(ctx);
                drawKLines(ctx);
                drawAxes(ctx);
            }
            
            function drawBackground(ctx) {
                ctx.fillStyle = "#2b2b2b";
                ctx.fillRect(0, 0, width, height);
            }
            
            function drawGrid(ctx) {
                ctx.strokeStyle = "#444444";
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 2]);
                
                // 垂直网格线
                var xStep = root.chartWidth / Math.max(1, root.klineData.length - 1);
                for (var i = 0; i <= root.klineData.length; i++) {
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
                if (root.klineData.length === 0) return;
                
                var candleWidth = root.chartWidth / root.klineData.length * 0.6;
                var candleSpacing = root.chartWidth / root.klineData.length;
                
                for (var i = 0; i < root.klineData.length; i++) {
                    var kline = root.klineData[i];
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
                    
                    if (bodyHeight < 1) bodyHeight = 1; // 最小高度
                    
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
                
                // X轴标签（时间）
                for (var j = 0; j < root.klineData.length; j++) {
                    var x = root.leftMargin + j * (root.chartWidth / root.klineData.length);
                    var timeStr = formatTime(root.klineData[j].time);
                    
                    // 调整文字位置，避免重叠
                    ctx.save();
                    ctx.translate(x, height - 5);
                    ctx.rotate(-Math.PI / 6); // 倾斜30度
                    ctx.fillText(timeStr, 0, 0);
                    ctx.restore();
                }
            }
            
            function formatTime(timeString) {
                // 解析时间字符串 "2025-08-14 11:26:50"
                var timeParts = timeString.split(' ');
                if (timeParts.length >= 2) {
                    var time = timeParts[1]; // "11:26:50"
                    var timeParts2 = time.split(':');
                    if (timeParts2.length >= 2) {
                        return timeParts2[0] + ":" + timeParts2[1]; // "11:26"
                    }
                }
                return "00:00";
            }
            
            function priceToY(price) {
                var ratio = (price - root.minPrice) / (root.maxPrice - root.minPrice);
                return root.topMargin + root.chartHeight - ratio * root.chartHeight;
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
    }
    
    // 数据提供器
    KLineDataProvider {
        id: dataProvider
        csvFile: root.csvFile
        
        onDataLoaded: {
            console.log("Canvas K线图: 数据加载完成, 共", data.length, "条数据，显示前10条");
            
            var tempData = [];
            var dataCount = Math.min(data.length, 10);
            
            root.minPrice = Number.MAX_VALUE;
            root.maxPrice = Number.MIN_VALUE;
            
            for (var i = 0; i < dataCount; i++) {
                var row = data[i];
                if (row.length >= 5) {
                    var kline = {
                        time: row[0],
                        open: parseFloat(row[1]),
                        high: parseFloat(row[2]),
                        low: parseFloat(row[3]),
                        close: parseFloat(row[4])
                    };
                    
                    tempData.push(kline);
                    
                    root.minPrice = Math.min(root.minPrice, kline.low);
                    root.maxPrice = Math.max(root.maxPrice, kline.high);
                }
            }
            
            // 添加一些边距
            var range = root.maxPrice - root.minPrice;
            root.minPrice -= range * 0.1;
            root.maxPrice += range * 0.1;
            
            root.klineData = tempData;
            
            console.log("Canvas K线图: 价格范围", root.minPrice.toFixed(2), "到", root.maxPrice.toFixed(2));
            console.log("Canvas K线图: K线数量", root.klineData.length);
            
            // 触发重绘
            canvas.requestPaint();
        }
    }
    
    Component.onCompleted: {
        console.log("Canvas K线图: csvFile =", csvFile);
        if (csvFile) {
            dataProvider.loadData();
        }
    }
}