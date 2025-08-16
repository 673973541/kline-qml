#ifndef KLINEDATAPROVIDER_H
#define KLINEDATAPROVIDER_H

#include <QMutex>
#include <QObject>
#include <QString>
#include <QThread>
#include <QVariantList>

// 异步数据处理Worker
class KLineDataWorker : public QObject
{
    Q_OBJECT

public slots:
    void processData(const QVariantList &rawData, const QString &targetPeriod);

signals:
    void dataProcessed(const QVariantList &processedData);

private:
    QVariantList synthesizeKLineData(const QVariantList &minuteData, const QString &targetPeriod);
    QVariantMap combineKLineData(const QVariantList &dataPoints);
    int getPeriodMinutes(const QString &period);
};

class KLineDataProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString csvFile READ csvFile WRITE setCsvFile NOTIFY csvFileChanged)
    Q_PROPERTY(QString klinePeriod READ klinePeriod WRITE setKlinePeriod NOTIFY klinePeriodChanged)
    Q_PROPERTY(QVariantList data READ data NOTIFY dataChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit KLineDataProvider(QObject *parent = nullptr);
    ~KLineDataProvider();

    QString csvFile() const;
    void setCsvFile(const QString &csvFile);

    QString klinePeriod() const;
    void setKlinePeriod(const QString &klinePeriod);

    QVariantList data() const;
    bool isLoading() const;

    Q_INVOKABLE void loadData();

signals:
    void csvFileChanged();
    void klinePeriodChanged();
    void dataChanged();
    void dataLoaded();
    void isLoadingChanged();
    void processDataRequest(const QVariantList &rawData, const QString &targetPeriod);

private slots:
    void onDataProcessed(const QVariantList &processedData);

private:
    void parseCSV(const QString &content);
    void startAsyncProcessing(const QString &targetPeriod);

    QString m_csvFile;
    QString m_klinePeriod;
    QVariantList m_rawData;  // 原始1分钟数据
    QVariantList m_data;     // 当前周期的数据
    bool m_isLoading;

    QThread *m_workerThread;
    KLineDataWorker *m_worker;
    mutable QMutex m_dataMutex;
};

#endif  // KLINEDATAPROVIDER_H