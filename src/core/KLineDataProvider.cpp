#include "klinedataprovider.h"

#include <ta_libc.h>

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QTextStream>
KLineDataProvider::KLineDataProvider(QObject *parent) : QObject(parent) {}

QString KLineDataProvider::csvFile() const { return m_csvFile; }

void KLineDataProvider::setCsvFile(const QString &csvFile)
{
    if (m_csvFile != csvFile) {
        qDebug() << "KLineDataProvider: CSV file changed to:" << csvFile;
        m_csvFile = csvFile;
        emit csvFileChanged();
    }
}

QVariantList KLineDataProvider::data() const { return m_data; }

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
            m_data.append(QVariant::fromValue(row));
        }
    }

    // 使用TA-lib计算MA(移动平均线)
    if (m_data.size() > 0) {
        // 准备输入数据
        const int dataSize = m_data.size();
        double *closePrice = new double[dataSize];

        // 从m_data中提取收盘价(假设收盘价在每行的第4个位置)
        for (int i = 0; i < dataSize; i++) {
            QVariantList row = m_data[i].toList();
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
                QVariantList row = m_data[dataIndex].toList();
                // 添加MA值作为额外字段
                row.append(outMA[i]);
                m_data[dataIndex] = QVariant::fromValue(row);
            }
        } else {
            qDebug() << "TA-Lib MA计算失败，错误码:" << retCode;
        }

        // 释放内存
        delete[] closePrice;
        delete[] outMA;
    }
    qDebug() << m_data.at(100).toList();  // 输出第一行数据以验证
    qDebug() << "KLineDataProvider: Parsed" << m_data.size() << "data rows";

    emit dataChanged();
    emit dataLoaded();
}