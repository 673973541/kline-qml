cmake_minimum_required(VERSION 3.16)

project(KLineChart VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

# Qt路径设置
set(CMAKE_PREFIX_PATH "C:/Qt/6.8.3/mingw_64")

# 查找Qt组件
find_package(Qt6 6.5 REQUIRED COMPONENTS
    Quick
    Qml
    Core
    Gui
)

# Qt标准项目设置
qt_standard_project_setup(REQUIRES 6.5)

# 收集源文件
set(SOURCES
    src/main.cpp
    src/core/KLineDataProvider.h
    src/core/KLineDataProvider.cpp
)

# 创建可执行文件
qt_add_executable(KLineChart ${SOURCES})

# 添加QML模块
qt_add_qml_module(KLineChart
    URI KLineModule
    VERSION 1.0
    QML_FILES
    qml/main.qml
    qml/components/charts/CanvasKLineChart.qml
    qml/components/charts/ChartBase.qml
    qml/components/charts/KLineCanvas.qml
    qml/components/charts/ChartInteraction.qml
    qml/components/charts/ChartTooltip.qml
    qml/components/data/KLineDataLoader.qml
    RESOURCES
)

# 设置目标属性
set_target_properties(KLineChart PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    # WIN32_EXECUTABLE TRUE  # 注释掉以启用控制台输出
)

# 链接Qt库
target_link_libraries(KLineChart PRIVATE
    Qt6::Quick
    Qt6::Qml
    Qt6::Core
    Qt6::Gui
)

# 设置包含目录
target_include_directories(KLineChart PRIVATE src)

# 编译选项
if(WIN32 AND MSVC)
    target_compile_definitions(KLineChart PRIVATE WIN32_LEAN_AND_MEAN)
    target_compile_options(KLineChart PRIVATE /Zc:__cplusplus /utf-8)
endif()

# 安装配置
include(GNUInstallDirs)
install(TARGETS KLineChart
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# 复制数据文件到构建目录
add_custom_command(TARGET KLineChart POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    ${CMAKE_SOURCE_DIR}/resources/data/sample_kline.csv
    $<TARGET_FILE_DIR:KLineChart>/sample_kline.csv
)

# 打印项目信息
message(STATUS "")
message(STATUS "=== KLine Chart项目配置 ===")
message(STATUS "项目名称: ${PROJECT_NAME}")
message(STATUS "版本: ${PROJECT_VERSION}")
message(STATUS "Qt版本: ${Qt6_VERSION}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")
message(STATUS "安装目录: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "=========================")
