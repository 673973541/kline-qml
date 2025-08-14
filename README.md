# 📈 专业K线图表应用

基于Qt6 + QML开发的专业级K线图表应用，采用Canvas绘制技术，支持实时数据显示和交互操作。

## ✨ 特性

- 🎨 **Canvas自定义绘制** - 高性能，完全可控的图表渲染
- 🔴🟢 **中式配色** - 涨红跌绿，符合中国用户习惯
- ⏰ **实时时间轴** - 显示真实时间标签，支持多种时间格式
- 💰 **精确价格轴** - 自动缩放，清晰的价格标注
- 🕯️ **标准K线** - 完整的OHLC蜡烛图显示
- 🏗️ **模块化架构** - 易于扩展和维护

## 🏗️ 项目结构

```
kline/
├── src/                          # C++源码
│   ├── main.cpp                  # 主程序入口
│   ├── core/                     # 核心业务逻辑
│   │   └── KLineDataProvider     # 数据提供器
│   └── utils/                    # 工具类
├── qml/                         # QML界面文件
│   ├── main.qml                 # 主入口
│   └── components/              # 可复用组件
│       └── charts/              # 图表组件
│           └── CanvasKLineChart.qml
├── resources/                   # 资源文件
│   └── data/                    # 示例数据
├── scripts/                     # 脚本文件
│   └── generate_kline.py        # 数据生成脚本
└── docs/                        # 文档
```

## 🚀 快速开始

### 环境要求

- Qt 6.5+
- CMake 3.16+
- C++17编译器

### 构建步骤

1. **克隆项目**
   ```bash
   git clone <your-repo-url>
   cd kline
   ```

2. **创建构建目录**
   ```bash
   mkdir build && cd build
   ```

3. **配置和构建**
   ```bash
   cmake ..
   cmake --build . --config Debug
   ```

4. **运行应用**
   ```bash
   ./KLineChart  # Linux/macOS
   KLineChart.exe  # Windows
   ```

## 📊 数据格式

支持CSV格式的K线数据：

```csv
时间,开盘,最高,最低,收盘
2025-08-14 09:30:00,100.00,100.50,99.50,100.20
2025-08-14 09:31:00,100.20,100.80,100.10,100.60
...
```

## 🔧 技术特点

### 架构设计
- **C++后端** - 负责数据处理和业务逻辑
- **QML前端** - 现代化的用户界面
- **Canvas绘制** - 高性能的图表渲染

### 核心组件
- `KLineDataProvider` - 数据提供和管理
- `CanvasKLineChart` - K线图表绘制组件
- 模块化QML组件体系

## 🎯 扩展计划

- [ ] 📱 移动端适配
- [ ] 🖱️ 鼠标交互（缩放、拖拽）
- [ ] 📊 技术指标（MA、MACD、RSI）
- [ ] 💾 多数据源支持
- [ ] 🎨 主题系统
- [ ] 📈 多图表类型

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

---

*基于Qt6开发的专业级金融图表应用* 🚀