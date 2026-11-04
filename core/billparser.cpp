#include "billparser.h"
#include "xlsxdocument.h"
#include <QDebug>
#include <QDateTime>

namespace {

int findHeaderRow(QXlsx::Document &xlsx) {
    auto dim = xlsx.dimension();
    int maxScan = qMin(30, dim.rowCount());
    for (int r = 1; r <= maxScan; ++r) {
        if (xlsx.read(r, 1).toString().trimmed() == "交易时间")
            return r;
    }
    return -1;
}

QVector<BillRecord> parseFromRow(QXlsx::Document &xlsx, int headerRow) {
    QVector<BillRecord> result;
    auto dim = xlsx.dimension();
    for (int r = headerRow + 1; r <= dim.rowCount(); ++r) {
        QString timeStr = xlsx.read(r, 1).toString().trimmed();
        if (timeStr.isEmpty()) continue;

        BillRecord rec;
        rec.time = QDateTime::fromString(timeStr, Qt::ISODateWithMs);
        if (!rec.time.isValid())
            rec.time = QDateTime::fromString(timeStr, Qt::ISODate);

        rec.type       = xlsx.read(r, 2).toString().trimmed();
        rec.peer       = xlsx.read(r, 3).toString().trimmed();
        rec.product    = xlsx.read(r, 4).toString().trimmed();
        rec.direction  = xlsx.read(r, 5).toString().trimmed();
        rec.amount     = xlsx.read(r, 6).toString().trimmed().toDouble();
        rec.status     = xlsx.read(r, 8).toString().trimmed();
        rec.tradeNo    = xlsx.read(r, 9).toString().trimmed();
        rec.merchantNo = xlsx.read(r, 10).toString().trimmed();
        rec.note       = xlsx.read(r, 11).toString().trimmed();

        if (!rec.time.isValid() || rec.tradeNo.isEmpty())
            continue;

        result.append(rec);
    }
    return result;
}

} // namespace

QVector<BillRecord> BillParser::parseXlsx(const QString &path,
                                          const QDateTime &stopAtTime,
                                          QString *error,
                                          QAtomicInt *cancelFlag) {
    QXlsx::Document xlsx(path);
    if (!xlsx.load()) {
        if (error) *error = "无法打开文件";
        return {};
    }

    int headerRow = findHeaderRow(xlsx);
    if (headerRow < 0) {
        if (error) *error = "未找到表头（交易时间）";
        return {};
    }

    QVector<BillRecord> result;
    auto dim = xlsx.dimension();

    for (int r = headerRow + 1; r <= dim.rowCount(); ++r) {
        if (cancelFlag && (r % 100 == 0) && cancelFlag->loadAcquire() != 0) {
            if (error) *error = "cancelled";
            return {};
        }

        QString timeStr = xlsx.read(r, 1).toString().trimmed();
        if (timeStr.isEmpty()) continue;

        BillRecord rec;
        rec.time = QDateTime::fromString(timeStr, Qt::ISODateWithMs);
        if (!rec.time.isValid())
            rec.time = QDateTime::fromString(timeStr, Qt::ISODate);

        if (stopAtTime.isValid() && rec.time.isValid() && rec.time < stopAtTime)
            break;

        rec.type       = xlsx.read(r, 2).toString().trimmed();
        rec.peer       = xlsx.read(r, 3).toString().trimmed();
        rec.product    = xlsx.read(r, 4).toString().trimmed();
        rec.direction  = xlsx.read(r, 5).toString().trimmed();
        rec.amount     = xlsx.read(r, 6).toString().trimmed().toDouble();
        rec.status     = xlsx.read(r, 8).toString().trimmed();
        rec.tradeNo    = xlsx.read(r, 9).toString().trimmed();
        rec.merchantNo = xlsx.read(r, 10).toString().trimmed();
        rec.note       = xlsx.read(r, 11).toString().trimmed();

        if (!rec.time.isValid() || rec.tradeNo.isEmpty())
            continue;

        result.append(rec);
    }
    return result;
}