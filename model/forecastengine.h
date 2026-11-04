#pragma once
#include <QVector>
#include <QPair>
#include <QString>

struct MonthForecast {
    int month = 0;
    double value = -1;   // -1 表示该月不预测（已过去）
};

class ForecastEngine {
public:
    static QVector<MonthForecast> predictLight(
        const QVector<QPair<QString, double>> &history,
        int targetYear);

    static QVector<MonthForecast> predictLong(
        const QVector<QPair<QString, double>> &history,
        int targetYear);

    static bool hasEnoughForLong(
        const QVector<QPair<QString, double>> &history);
};