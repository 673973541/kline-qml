cmake_minimum_required(VERSION 3.16)

project(KLineChart VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

set(QT_QML_GENERATE_QMLLS_INI ON)

# Qt路径设置
set(CMAKE_PREFIX_PATH "C:/Qt/6.8.3/mingw_64")

# 查找Qt组件
find_package(Qt6 6.5 REQUIRED COMPONENTS
    Quick
    QuickControls2
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

# 设置Windows环境变量以兼容TA-Lib的CMakeLists.txt检查
if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ENV{Platform} "x64")
    else()
        set(ENV{Platform} "x86")
    endif()
endif()

# 添加TA-Lib源码子项目
add_subdirectory(thrid_party/ta_lib)

# 设置TA-Lib头文件路径
set(TALIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thrid_party/ta_lib/include")
include_directories(${TALIB_INCLUDE_DIR})

# 链接Qt库和TA-Lib库
target_link_libraries(KLineChart PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
    Qt6::Core
    Qt6::Gui
    ta-lib-static # 链接TA-Lib静态库
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

