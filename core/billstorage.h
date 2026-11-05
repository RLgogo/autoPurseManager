#pragma once
#include "billrecord.h"
#include <QString>
#include <QVector>
#include <QDateTime>


class BillStorage {
public:
    struct DailySummary {
        QString yearMonth;
        int day = 0;
        double expense = 0;
        double income = 0;
    };
    static QVector<QPair<QString, double>> monthlyTotals(int months,
                                                         QString *error = nullptr);
    static QVector<QPair<QString, double>> topMerchants(int year, int month,
                                                        int limit = 6,
                                                        QString *error = nullptr);
    static QVector<QPair<QString, double>> topMerchantsAll(int limit = 6,
                                                           QString *error = nullptr);
    static double totalExpenseAll(QString *error = nullptr);
    static QVector<QPair<int, double>> monthlyExpenseForYear(int year,
                                                             QString *error = nullptr);
    static QVector<QPair<int, double>> dailyExpenseForMonth(int year, int month,
                                                            QString *error = nullptr);
    static QString learnedCategory(const QString &peer, const QString &product);
    static void learnCategory(const QString &peer, const QString &product,
                              const QString &category);
    static QVector<QPair<QString, double>> categoryStats(int days,
                                                         QString *error = nullptr);
    static QDateTime lastMaxTime();
    static void setLastMaxTime(const QDateTime &time);

    static bool init(const QString &dbPath, QString *error = nullptr);
    static int insertRecords(const QVector<BillRecord> &records,
                             int *skipped = nullptr,
                             QString *error = nullptr);
    static QVector<QPair<int, double>> dailyNetForMonth(int year, int month,
                                                        QString *error = nullptr);
    static QVector<QPair<int, double>> monthlyNetForYear(int year,
                                                         QString *error = nullptr);
    struct ImportHistory {
        qint64 id = 0;
        QString importId;
        QString fileName;
        QString filePath;
        int recordCount = 0;
        QString minTime;
        QString maxTime;
        QString importTime;
    };

    static int insertRecords(const QVector<BillRecord> &records,
                             int *skipped = nullptr,
                             QString *error = nullptr,
                             const QString &importId = {},
                             const QString &fileName = {},
                             const QString &filePath = {});
    static QVector<ImportHistory> importHistory(QString *error = nullptr);
    static int totalBillCount(QString *error = nullptr);
    static bool deleteImport(qint64 historyId, QString *error = nullptr);
    static int totalCount(QString *error = nullptr);
    static QVector<BillRecord> fetchAll(QString *error = nullptr);

    static bool isFileAlreadyImported(const QString &path, qint64 size,
                                      const QDateTime &mtime);
    // 仅按路径判断：content:// URI 没有可靠的修改时间/大小，用它去重。
    static bool isFileImported(const QString &path);
    static void markFileImported(const QString &path, qint64 size,
                                 const QDateTime &mtime);

    static void rebuildAllSummaries(QString *error = nullptr);
    static void refreshMonthSummary(const QString &yearMonth,
                                    QString *error = nullptr);
    static QVector<DailySummary> summariesForMonths(const QStringList &yearMonths,
                                                    QString *error = nullptr);
};