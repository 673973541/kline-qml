import QtQuick
import QtQuick.Controls
import "components/charts"

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    visible: true
    title: qsTr("专业K线图表")
    
    Component.onCompleted: {
        console.log("KLine应用启动完成");
    }

    CanvasKLineChart {
        anchors.fill: parent
        csvFile: "sample_kline.csv"
    }
}
