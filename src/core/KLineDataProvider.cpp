#include "klinedataprovider.h"

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

    qDebug() << "KLineDataProvider: Parsed" << m_data.size() << "data rows";

    emit dataChanged();
    emit dataLoaded();
}