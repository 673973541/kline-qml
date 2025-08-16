import random
import datetime
import csv


def generate_kline_data(n, base_price=100, volatility=0.02):
    """
    生成n条分钟K线数据

    参数:
    n: 生成K线数量
    base_price: 基础价格
    volatility: 波动率

    返回:
    list: 包含K线数据的列表，每条数据格式为 [时间, 开盘, 最高, 最低, 收盘]
    """
    klines = []
    # 使用今天的开始时间，避免未来时间
    current_time = datetime.datetime.now().replace(
        hour=9, minute=30, second=0, microsecond=0
    )
    current_price = base_price

    for i in range(n):
        # 生成开盘价（基于前一个收盘价）
        open_price = current_price

        # 生成随机波动
        change_rate = random.uniform(-volatility, volatility)
        close_price = open_price * (1 + change_rate)

        # 生成最高价和最低价
        high_low_range = abs(close_price - open_price) * random.uniform(1.0, 2.0)

        if close_price > open_price:
            high_price = max(open_price, close_price) + random.uniform(
                0, high_low_range * 0.5
            )
            low_price = min(open_price, close_price) - random.uniform(
                0, high_low_range * 0.3
            )
        else:
            high_price = max(open_price, close_price) + random.uniform(
                0, high_low_range * 0.3
            )
            low_price = min(open_price, close_price) - random.uniform(
                0, high_low_range * 0.5
            )

        # 确保价格逻辑正确：low <= open,close <= high
        low_price = min(low_price, open_price, close_price)
        high_price = max(high_price, open_price, close_price)

        # 格式化数据
        timestamp = current_time.strftime("%Y-%m-%d %H:%M:%S")
        kline = [
            timestamp,
            round(open_price, 2),
            round(high_price, 2),
            round(low_price, 2),
            round(close_price, 2),
        ]
        klines.append(kline)

        # 更新下一分钟的时间和价格
        current_time += datetime.timedelta(minutes=1)
        current_price = close_price

    return klines


def save_to_csv(klines, filename="kline_data.csv"):
    """保存K线数据到CSV文件"""
    with open(filename, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["时间", "开盘", "最高", "最低", "收盘"])
        writer.writerows(klines)
    print(f"K线数据已保存到 {filename}")


def print_klines(klines):
    """打印K线数据"""
    print("时间\t\t\t开盘\t最高\t最低\t收盘")
    print("-" * 60)
    for kline in klines:
        print(f"{kline[0]}\t{kline[1]}\t{kline[2]}\t{kline[3]}\t{kline[4]}")


if __name__ == "__main__":
    n = 10000
    kline_data = generate_kline_data(n)
    save_to_csv(kline_data)
