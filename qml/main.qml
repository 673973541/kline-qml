import QtQuick
import QtQuick.Controls
import "components/charts"
import "components/data"

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    visible: true
    title: qsTr("专业K线图表")
    Component.onCompleted: {
        console.log("KLine应用启动完成");
    }

    // 数据加载器
    KLineDataLoader {
        id: dataLoader

        csvFile: "sample_kline.csv"
    }

    // K线图表
    CanvasKLineChart {
        anchors.fill: parent
        klineData: dataLoader.klineData
        title: "专业K线图表"
    }

}
