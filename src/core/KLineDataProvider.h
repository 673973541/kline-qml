#ifndef KLINEDATAPROVIDER_H
#define KLINEDATAPROVIDER_H

#include <QObject>
#include <QVariantList>
#include <QString>

class KLineDataProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString csvFile READ csvFile WRITE setCsvFile NOTIFY csvFileChanged)
    Q_PROPERTY(QVariantList data READ data NOTIFY dataChanged)

public:
    explicit KLineDataProvider(QObject *parent = nullptr);

    QString csvFile() const;
    void setCsvFile(const QString &csvFile);

    QVariantList data() const;

    Q_INVOKABLE void loadData();

signals:
    void csvFileChanged();
    void dataChanged();
    void dataLoaded();

private:
    void parseCSV(const QString &content);

    QString m_csvFile;
    QVariantList m_data;
};

#endif // KLINEDATAPROVIDER_H