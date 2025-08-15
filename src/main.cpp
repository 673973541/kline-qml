#include <ta_libc.h>

#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QtQml>

#include "core/KLineDataProvider.h"

int main(int argc, char *argv[])
{
    // 初始化TA-Lib
    TA_RetCode taInitResult = TA_Initialize();
    if (taInitResult != TA_SUCCESS) {
        qDebug() << "TA-Lib初始化失败，错误码:" << taInitResult;
        return -1;
    }
    qDebug() << "TA-Lib初始化成功";

    QGuiApplication app(argc, argv);

    // 设置Qt Quick Controls样式为Basic，避免原生样式限制
    QQuickStyle::setStyle("Basic");

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
    const QUrl url(QStringLiteral("qrc:/qt/qml/KLineModule/qml/main.qml"));
    engine.load(url);

    qDebug() << "应用程序运行中...";

    int result = app.exec();

    // 关闭TA-Lib
    TA_Shutdown();
    qDebug() << "TA-Lib已关闭";

    return result;
}
