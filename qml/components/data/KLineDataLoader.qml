import KLineModule
import QtQuick

Item {
    id: root

    // 输入属性
    property string csvFile: ""
    property string klinePeriod: "1m"  // 默认1分钟周期
    // 输出属性
    property var klineData: []
    property bool isLoading: dataProvider.isLoading

    // 信号
    signal dataLoaded(var data)
    signal dataError(string error)

    // 数据提供器
    KLineDataProvider {
        id: dataProvider

        onCsvFileChanged: {
            if (csvFile)
                loadData();
        }
        csvFile: root.csvFile
        klinePeriod: root.klinePeriod
        onDataLoaded: {
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
            root.dataLoaded(tempData);
        }
    }
}
