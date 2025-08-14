#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QtQml>

#include "core/KLineDataProvider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qDebug() << "K线图应用启动...";

    // 注册C++类到QML
    qmlRegisterType<KLineDataProvider>("KLineModule", 1, 0, "KLineDataProvider");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() {
            qDebug() << "QML对象创建失败！";
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    const QUrl url(QStringLiteral("qrc:/qt/qml/kline/main.qml"));
    engine.load(url);

    qDebug() << "应用程序运行中...";
    return app.exec();
}
