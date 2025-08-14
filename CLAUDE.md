# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 语言偏好

请始终使用中文进行交流和代码注释。

## Project Overview

This is a professional K-line (candlestick) chart application built with **Qt6 + QML**. It's a financial charting application that displays real-time OHLC (Open, High, Low, Close) data using Canvas-based custom drawing for high performance rendering.

## Build and Development Commands

### Environment Requirements
- Qt 6.5+
- CMake 3.16+
- C++17 compiler
- Qt path configured at: `C:/Qt/6.8.3/mingw_64`

### Build Commands
```bash
# Create and enter build directory
mkdir build && cd build

# Configure project
cmake ..

# Build (Debug)
cmake --build . --config Debug

# Build (Release)
cmake --build . --config Release

# Run application
./KLineChart.exe  # Windows
```

### Testing
Run tests from the tests/unit directory (implementation TBD).

## Architecture

### Core Components
- **C++ Backend**: Data processing and business logic
  - `KLineDataProvider` (src/core/): Main data provider class that loads and parses CSV K-line data
  - Exposes data to QML via Qt's property system and Q_INVOKABLE methods
  
- **QML Frontend**: Modern UI with Canvas-based chart rendering
  - `main.qml`: Application entry point with 1200x800 window
  - `CanvasKLineChart.qml`: High-performance Canvas-based K-line chart component
  - Supports Chinese-style coloring (red for rising, green for falling prices)

### Data Flow
1. CSV data loaded via `KLineDataProvider::loadData()`
2. Data parsed and exposed as QVariantList to QML
3. QML Canvas component renders K-line charts with custom drawing functions
4. Real-time updates trigger canvas repaints

### Key Technical Features
- **Canvas Custom Drawing**: High-performance chart rendering using QML Canvas
- **Modular QML Architecture**: Reusable chart components
- **CSV Data Support**: Format: `时间,开盘,最高,最低,收盘`
- **Responsive Scaling**: Automatic price axis scaling with margins
- **Time Axis**: Formatted time labels with rotation for readability

### File Structure
- `src/core/KLineDataProvider.*`: Data provider implementation
- `qml/main.qml`: Main application window
- `qml/components/charts/CanvasKLineChart.qml`: Chart rendering component
- `resources/data/sample_kline.csv`: Sample data file
- `scripts/generate_kline.py`: Data generation utility

## Development Notes

- The project uses CMake with Qt6's modern cmake integration
- QML module URI: `KLineModule` 
- Sample CSV data is automatically copied to build directory
- Console output enabled for debugging (WIN32_EXECUTABLE commented out)
- Chinese language support throughout UI and documentation