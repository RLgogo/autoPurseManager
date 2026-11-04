#include "forecastengine.h"
#include <QDate>
#include <QtMath>
#include <QtGlobal>

static void parseYM(const QString &ym, int &y, int &m) {
    QStringList parts = ym.split('-');
    if (parts.size() == 2) {
        y = parts[0].toInt();
        m = parts[1].toInt();
    }
}

static void linearFit(const QVector<double> &xs, const QVector<double> &ys,
                      double &slope, double &intercept) {
    int n = xs.size();
    if (n < 2) {
        slope = 0;
        intercept = ys.isEmpty() ? 0 : ys[0];
        return;
    }
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; ++i) {
        sumX += xs[i];
        sumY += ys[i];
        sumXY += xs[i] * ys[i];
        sumX2 += xs[i] * xs[i];
    }
    double denom = n * sumX2 - sumX * sumX;
    if (qFuzzyIsNull(denom)) {
        slope = 0;
        intercept = sumY / n;
        return;
    }
    slope = (n * sumXY - sumX * sumY) / denom;
    intercept = (sumY - slope * sumX) / n;
}

static double predictOneLight(const QVector<QPair<QString, double>> &prior,
                              const QString &targetYM) {
    int n = prior.size();
    if (n == 0) return -99999;

    double base = 0, wsum = 0;
    int cnt = qMin(3, n);
    for (int i = 0; i < cnt; ++i) {
        double w = (cnt == 3) ? (0.5 - 0.1 * i) : (1.0 / cnt);
        base += prior[n - 1 - i].second * w;
        wsum += w;
    }
    if (wsum > 0) base /= wsum;

    QVector<double> xs, ys;
    for (int i = 0; i < n; ++i) {
        xs.append(i);
        ys.append(prior[i].second);
    }
    double slope = 0, intercept = 0;
    linearFit(xs, ys, slope, intercept);

    int lastY, lastM;
    parseYM(prior.last().first, lastY, lastM);
    int tY, tM;
    parseYM(targetYM, tY, tM);
    int step = (tY - lastY) * 12 + (tM - lastM);

    double v = base + slope * step;
    if (v < 0) v = 0;

    int days = QDate(tY, tM, 1).daysInMonth();
    v *= (days / 30.0);
    return v;
}

static double predictOneLong(const QVector<QPair<QString, double>> &prior,
                             const QString &targetYM) {
    int n = prior.size();
    if (n < 24) return -99999;

    QVector<QVector<double>> byMonth(13);
    for (const auto &p : prior) {
        int y, m;
        parseYM(p.first, y, m);
        if (m >= 1 && m <= 12) byMonth[m].append(p.second);
    }

    double total = 0;
    int count = 0;
    for (int m = 1; m <= 12; ++m) {
        for (double v : byMonth[m]) { total += v; ++count; }
    }
    if (count == 0) return -1;
    double globalAvg = total / count;

    QVector<double> xs, ys;
    for (int i = 0; i < n; ++i) {
        xs.append(i);
        ys.append(prior[i].second);
    }
    double slope = 0, intercept = 0;
    linearFit(xs, ys, slope, intercept);

    int lastY, lastM;
    parseYM(prior.last().first, lastY, lastM);
    int tY, tM;
    parseYM(targetYM, tY, tM);
    int step = (tY - lastY) * 12 + (tM - lastM);

    double trendValue = intercept + slope * (n - 1 + step);
    if (trendValue < 0) trendValue = 0;

    double season = 1.0;
    if (globalAvg > 0 && !byMonth[tM].isEmpty()) {
        double sum = 0;
        for (double v : byMonth[tM]) sum += v;
        season = (sum / byMonth[tM].size()) / globalAvg;
    }

    double v = trendValue * season;
    int days = QDate(tY, tM, 1).daysInMonth();
    v *= (days / 30.0);
    return v;
}

QVector<MonthForecast> ForecastEngine::predictLight(
    const QVector<QPair<QString, double>> &history, int targetYear) {

    QVector<MonthForecast> result;
    for (int m = 1; m <= 12; ++m) {
        MonthForecast f;
        f.month = m;
        f.value = -99999;
        result.append(f);
    }
    if (history.isEmpty()) return result;

    for (int m = 1; m <= 12; ++m) {
        QString targetYM = QString("%1-%2").arg(targetYear).arg(m, 2, 10, QChar('0'));

        QVector<QPair<QString, double>> prior;
        for (const auto &p : history) {
            if (p.first < targetYM) prior.append(p);
        }

        if (prior.isEmpty()) continue;
        result[m - 1].value = predictOneLight(prior, targetYM);
    }
    return result;
}

QVector<MonthForecast> ForecastEngine::predictLong(
    const QVector<QPair<QString, double>> &history, int targetYear) {

    QVector<MonthForecast> result;
    for (int m = 1; m <= 12; ++m) {
        MonthForecast f;
        f.month = m;
        f.value = -99999;
        result.append(f);
    }

    for (int m = 1; m <= 12; ++m) {
        QString targetYM = QString("%1-%2").arg(targetYear).arg(m, 2, 10, QChar('0'));

        QVector<QPair<QString, double>> prior;
        for (const auto &p : history) {
            if (p.first < targetYM) prior.append(p);
        }

        if (prior.size() < 24) continue;
        result[m - 1].value = predictOneLong(prior, targetYM);
    }
    return result;
}

bool ForecastEngine::hasEnoughForLong(
    const QVector<QPair<QString, double>> &history) {
    return history.size() >= 24;
}