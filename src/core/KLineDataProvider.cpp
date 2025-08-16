#include "klinedataprovider.h"

#include <ta_libc.h>

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QMutexLocker>
#include <QStandardPaths>
#include <QTextStream>

// KLineDataWorker 实现
void KLineDataWorker::processData(const QVariantList &rawData, const QString &targetPeriod)
{
    qDebug() << "KLineDataWorker: 开始异步处理数据，数据量:" << rawData.size()
             << "周期:" << targetPeriod;

    QVariantList result;
    if (targetPeriod == "1m") {
        result = rawData;
    } else {
        result = synthesizeKLineData(rawData, targetPeriod);
    }

    qDebug() << "KLineDataWorker: 异步处理完成，结果数量:" << result.size();
    emit dataProcessed(result);
}

QVariantList KLineDataWorker::synthesizeKLineData(const QVariantList &minuteData,
                                                  const QString &targetPeriod)
{
    QVariantList result;

    if (minuteData.isEmpty()) {
        return result;
    }

    int periodMinutes = getPeriodMinutes(targetPeriod);
    if (periodMinutes <= 0) {
        qDebug() << "Invalid period:" << targetPeriod;
        return result;
    }

    QVariantList currentPeriodData;
    QDateTime currentPeriodStart;

    for (const QVariant &item : minuteData) {
        QVariantList row = item.toList();
        if (row.size() < 5) continue;

        // 解析时间戳
        QString timeStr = row[0].toString();
        QDateTime dateTime = QDateTime::fromString(timeStr, "yyyy-MM-dd hh:mm:ss");
        if (!dateTime.isValid()) {
            // 尝试其他时间格式
            dateTime = QDateTime::fromString(timeStr, "yyyy/MM/dd hh:mm:ss");
        }
        if (!dateTime.isValid()) {
            continue;
        }

        // 计算当前数据点应该属于哪个周期
        QDateTime periodStart;
        if (targetPeriod.endsWith("m")) {
            // 分钟级别的周期
            int minute = dateTime.time().minute();
            int alignedMinute = (minute / periodMinutes) * periodMinutes;
            periodStart = QDateTime(dateTime.date(), QTime(dateTime.time().hour(), alignedMinute));
        } else if (targetPeriod.endsWith("h")) {
            // 小时级别的周期
            int periodHours = periodMinutes / 60;  // 转换为小时数
            int hour = dateTime.time().hour();
            int alignedHour = (hour / periodHours) * periodHours;
            periodStart = QDateTime(dateTime.date(), QTime(alignedHour, 0));
        } else if (targetPeriod == "1d") {
            // 日级别的周期
            periodStart = QDateTime(dateTime.date(), QTime(0, 0));
        }

        // 如果是新的周期，处理之前的数据
        if (currentPeriodStart.isValid() && periodStart != currentPeriodStart) {
            if (!currentPeriodData.isEmpty()) {
                QVariantMap combinedData = combineKLineData(currentPeriodData);
                if (!combinedData.isEmpty()) {
                    QVariantList combinedRow;
                    combinedRow << combinedData["time"].toString()
                                << combinedData["open"].toDouble()
                                << combinedData["high"].toDouble() << combinedData["low"].toDouble()
                                << combinedData["close"].toDouble();
                    result.append(QVariant::fromValue(combinedRow));
                }
            }
            currentPeriodData.clear();
        }

        currentPeriodStart = periodStart;
        currentPeriodData.append(item);
    }

    // 处理最后一个周期的数据
    if (!currentPeriodData.isEmpty()) {
        QVariantMap combinedData = combineKLineData(currentPeriodData);
        if (!combinedData.isEmpty()) {
            QVariantList combinedRow;
            combinedRow << combinedData["time"].toString() << combinedData["open"].toDouble()
                        << combinedData["high"].toDouble() << combinedData["low"].toDouble()
                        << combinedData["close"].toDouble();
            result.append(QVariant::fromValue(combinedRow));
        }
    }

    return result;
}

QVariantMap KLineDataWorker::combineKLineData(const QVariantList &dataPoints)
{
    QVariantMap result;

    if (dataPoints.isEmpty()) {
        return result;
    }

    double open = 0, high = 0, low = 0, close = 0;
    QString timeStr;
    bool first = true;

    for (const QVariant &item : dataPoints) {
        QVariantList row = item.toList();
        if (row.size() < 5) continue;

        double currentOpen = row[1].toDouble();
        double currentHigh = row[2].toDouble();
        double currentLow = row[3].toDouble();
        double currentClose = row[4].toDouble();

        if (first) {
            timeStr = row[0].toString();
            open = currentOpen;
            high = currentHigh;
            low = currentLow;
            close = currentClose;
            first = false;
        } else {
            // 更新最高价和最低价
            if (currentHigh > high) high = currentHigh;
            if (currentLow < low) low = currentLow;
            // 收盘价使用最后一个数据点的收盘价
            close = currentClose;
        }
    }

    result["time"] = timeStr;
    result["open"] = open;
    result["high"] = high;
    result["low"] = low;
    result["close"] = close;

    return result;
}

int KLineDataWorker::getPeriodMinutes(const QString &period)
{
    if (period == "1m") return 1;
    if (period == "5m") return 5;
    if (period == "15m") return 15;
    if (period == "30m") return 30;
    if (period == "1h") return 60;
    if (period == "4h") return 240;
    if (period == "1d") return 1440;

    return -1;  // 无效周期
}

// KLineDataProvider 实现
KLineDataProvider::KLineDataProvider(QObject *parent)
    : QObject(parent), m_klinePeriod("1m"), m_isLoading(false)
{
    // 创建工作线程和worker
    m_workerThread = new QThread(this);
    m_worker = new KLineDataWorker();
    m_worker->moveToThread(m_workerThread);

    // 连接信号和槽
    connect(this, &KLineDataProvider::processDataRequest, m_worker, &KLineDataWorker::processData);
    connect(m_worker, &KLineDataWorker::dataProcessed, this, &KLineDataProvider::onDataProcessed);

    // 启动工作线程
    m_workerThread->start();
}

KLineDataProvider::~KLineDataProvider()
{
    // 停止工作线程
    if (m_workerThread && m_workerThread->isRunning()) {
        m_workerThread->quit();
        m_workerThread->wait();
    }

    // 删除worker (它在另一个线程中)
    if (m_worker) {
        m_worker->deleteLater();
    }
}

QString KLineDataProvider::csvFile() const { return m_csvFile; }

void KLineDataProvider::setCsvFile(const QString &csvFile)
{
    if (m_csvFile != csvFile) {
        qDebug() << "KLineDataProvider: CSV file changed to:" << csvFile;
        m_csvFile = csvFile;
        emit csvFileChanged();
    }
}

QString KLineDataProvider::klinePeriod() const { return m_klinePeriod; }

void KLineDataProvider::setKlinePeriod(const QString &klinePeriod)
{
    if (m_klinePeriod != klinePeriod) {
        qDebug() << "KLineDataProvider: Period changed to:" << klinePeriod;
        m_klinePeriod = klinePeriod;
        emit klinePeriodChanged();

        // 如果已有原始数据，启动异步处理
        if (!m_rawData.isEmpty()) {
            startAsyncProcessing(m_klinePeriod);
        }
    }
}

QVariantList KLineDataProvider::data() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_data;
}

bool KLineDataProvider::isLoading() const { return m_isLoading; }

void KLineDataProvider::startAsyncProcessing(const QString &targetPeriod)
{
    if (m_isLoading) {
        qDebug() << "KLineDataProvider: 已经在处理中，忽略新请求";
        return;
    }

    m_isLoading = true;
    emit isLoadingChanged();

    qDebug() << "KLineDataProvider: 启动异步处理，数据量:" << m_rawData.size()
             << "周期:" << targetPeriod;
    emit processDataRequest(m_rawData, targetPeriod);
}

void KLineDataProvider::onDataProcessed(const QVariantList &processedData)
{
    {
        QMutexLocker locker(&m_dataMutex);
        m_data = processedData;
    }

    m_isLoading = false;
    emit isLoadingChanged();
    emit dataChanged();
    emit dataLoaded();

    qDebug() << "KLineDataProvider: 异步处理完成，最终数据量:" << processedData.size();
}

void KLineDataProvider::loadData()
{
    if (m_csvFile.isEmpty()) {
        qDebug() << "KLineDataProvider: CSV file path is empty";
        return;
    }

    qDebug() << "KLineDataProvider: Loading CSV file:" << m_csvFile;

    // 构建完整的文件路径
    QString filePath;
    if (QFile::exists(m_csvFile)) {
        filePath = m_csvFile;
    } else {
        // 尝试从应用程序目录查找
        QString appDir = QCoreApplication::applicationDirPath();
        filePath = QDir(appDir).absoluteFilePath(m_csvFile);
    }

    qDebug() << "KLineDataProvider: Trying to load file:" << filePath;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "KLineDataProvider: Failed to open file:" << filePath;
        qDebug() << "KLineDataProvider: Error:" << file.errorString();
        return;
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    QString content = in.readAll();
    file.close();

    qDebug() << "KLineDataProvider: File loaded successfully, size:" << content.length();

    parseCSV(content);
}

void KLineDataProvider::parseCSV(const QString &content)
{
    m_rawData.clear();
    m_data.clear();

    QStringList lines = content.split('\n', Qt::SkipEmptyParts);
    if (lines.isEmpty()) {
        qDebug() << "KLineDataProvider: CSV file is empty";
        return;
    }

    // 跳过标题行
    for (int i = 1; i < lines.size(); ++i) {
        QString line = lines[i].trimmed();
        if (line.isEmpty()) continue;

        QStringList values = line.split(',');
        if (values.size() >= 5) {
            QVariantList row;
            // 清理数据并添加到行中
            for (const QString &value : values) {
                row.append(value.trimmed().remove('"'));
            }
            m_rawData.append(QVariant::fromValue(row));
        }
    }

    // 使用TA-lib计算MA(移动平均线)
    if (m_rawData.size() > 0) {
        // 准备输入数据
        const int dataSize = m_rawData.size();
        double *closePrice = new double[dataSize];

        // 从m_rawData中提取收盘价(假设收盘价在每行的第4个位置)
        for (int i = 0; i < dataSize; i++) {
            QVariantList row = m_rawData[i].toList();
            if (row.size() >= 5) {
                closePrice[i] = row[4].toDouble();  // 通常第5列是收盘价
            }
        }

        // 计算MA的参数
        const int maPeriod = 5;  // 设置MA周期为5
        int outBegIdx, outNbElement;
        double *outMA = new double[dataSize];

        // 调用TA-Lib MA函数计算简单移动平均线
        TA_RetCode retCode = TA_MA(0, dataSize - 1, closePrice, maPeriod, TA_MAType_SMA, &outBegIdx,
                                   &outNbElement, outMA);

        if (retCode == TA_SUCCESS) {
            qDebug() << "计算MA成功: 开始索引=" << outBegIdx << ", 结果元素数量=" << outNbElement;

            // 将MA值添加到每个数据点中
            for (int i = 0; i < outNbElement; i++) {
                int dataIndex = i + outBegIdx;
                QVariantList row = m_rawData[dataIndex].toList();
                // 添加MA值作为额外字段
                row.append(outMA[i]);
                m_rawData[dataIndex] = QVariant::fromValue(row);
            }
        } else {
            qDebug() << "TA-Lib MA计算失败，错误码:" << retCode;
        }

        // 释放内存
        delete[] closePrice;
        delete[] outMA;
    }

    qDebug() << "KLineDataProvider: Parsed" << m_rawData.size() << "raw data rows";

    // 启动异步处理来合成当前周期的数据
    startAsyncProcessing(m_klinePeriod);
}