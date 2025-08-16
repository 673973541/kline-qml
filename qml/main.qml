import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
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
        klinePeriod: periodComboBox.getCurrentValue()
    }

    // 顶部工具栏
    Rectangle {
        id: toolbar

        width: parent.width
        height: 60
        color: "#2e3440"
        z: 100

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Button {
                id: fileButton
                text: "选择CSV文件"
                height: 40
                onClicked: {
                    console.log("打开文件选择对话框");
                    fileDialog.open();
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dataLoader.csvFile ? "当前文件: " + dataLoader.csvFile : "未选择文件"
                color: "#d8dee9"
                font.pixelSize: 14
            }

            // K线周期选择
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "周期:"
                color: "#d8dee9"
                font.pixelSize: 14
            }

            ComboBox {
                id: periodComboBox
                width: 120
                height: 40

                property var periodData: [
                    {
                        text: "1分钟",
                        value: "1m"
                    },
                    {
                        text: "5分钟",
                        value: "5m"
                    },
                    {
                        text: "15分钟",
                        value: "15m"
                    },
                    {
                        text: "30分钟",
                        value: "30m"
                    },
                    {
                        text: "1小时",
                        value: "1h"
                    },
                    {
                        text: "4小时",
                        value: "4h"
                    },
                    {
                        text: "1天",
                        value: "1d"
                    }
                ]

                function getCurrentValue() {
                    return periodData[currentIndex].value;
                }

                model: periodData
                textRole: "text"
                currentIndex: 0  // 默认选择1分钟

                onCurrentIndexChanged: {
                    console.log("周期切换到:", getCurrentValue());
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "当前周期: " + periodComboBox.periodData[periodComboBox.currentIndex].text
                color: "#d8dee9"
                font.pixelSize: 14
            }

            // 加载指示器
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dataLoader.isLoading ? "数据处理中..." : ""
                color: "#88c0d0"
                font.pixelSize: 14
                visible: dataLoader.isLoading
            }
        }
    }

    // K线图表
    CanvasKLineChart {
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        klineData: dataLoader.klineData
        title: "专业K线图表"
    }

    // 文件选择对话框
    FileDialog {
        // 移除file:///

        id: fileDialog

        title: "选择K线数据文件"
        nameFilters: ["CSV 文件 (*.csv)", "所有文件 (*.*)"]
        onAccepted: {
            console.log("选择的文件:" + selectedFile);
            var filePath = selectedFile.toString();
            // 在Windows上正确处理文件URL
            if (filePath.startsWith("file:///"))
                filePath = filePath.substring(8);
            else if (filePath.startsWith("file://"))
                filePath = filePath.substring(7);
            // 移除file://
            console.log("处理后的路径:" + filePath);
            dataLoader.csvFile = filePath;
        }
        onRejected: {
            console.log("取消选择文件");
        }
    }
}
