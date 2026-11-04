#include "billmodel.h"
#include "core/billparser.h"
#include "core/billstorage.h"
#include "core/billclassifier.h"
#include "forecastengine.h"
#include <QDate>
#include <QMap>
#include <QVariantMap>
#include <QFileInfo>
#include <QUrl>
#include <QUuid>
#include <QtConcurrent/QtConcurrentRun>
#include <QFuture>

BillModel::BillModel(QObject *parent) : QAbstractListModel(parent) {}

int BillModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return m_records.size();
}

QVariant BillModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_records.size())
        return {};
    const auto &r = m_records[index.row()];
    switch (role) {
    case TimeRole:      return r.time.toString("yyyy-MM-dd HH:mm");
    case PeerRole:      return r.peer;
    case DirectionRole: return r.direction;
    case AmountRole:    return r.amount;
    }
    return {};
}

QHash<int, QByteArray> BillModel::roleNames() const {
    return {
        {TimeRole, "time"},
        {PeerRole, "peer"},
        {DirectionRole, "direction"},
        {AmountRole, "amount"}
    };
}

void BillModel::setRecords(const QVector<BillRecord> &records) {
    beginResetModel();
    m_records = records;
    endResetModel();
}

double BillModel::todayExpense() const {
    QDate today = QDate::currentDate();
    double sum = 0;
    for (const auto &r : m_records) {
        if (r.direction == "支出" && r.time.date() == today)
            sum += r.amount;
    }
    return sum;
}

double BillModel::monthExpense() const {
    QDate today = QDate::currentDate();
    double sum = 0;
    for (const auto &r : m_records) {
        if (r.direction == "支出"
            && r.time.date().year() == today.year()
            && r.time.date().month() == today.month())
            sum += r.amount;
    }
    return sum;
}

QVariantList BillModel::dailyExpense(int days) const {
    QVariantList list;
    QDate end = QDate::currentDate();
    QDate start = end.addDays(-(days - 1));

    QStringList months;
    for (QDate d = start; d <= end; d = d.addDays(1)) {
        QString m = d.toString("yyyy-MM");
        if (!months.contains(m)) months << m;
    }

    auto summaries = BillStorage::summariesForMonths(months);
    QMap<QString, double> byDate;
    for (const auto &s : summaries) {
        QString key = s.yearMonth + "-"
                    + QString("%1").arg(s.day, 2, 10, QChar('0'));
        byDate[key] = s.expense;
    }

    for (QDate d = start; d <= end; d = d.addDays(1)) {
        QVariantMap item;
        item["date"] = d.toString("MM-dd");
        item["amount"] = byDate.value(d.toString("yyyy-MM-dd"), 0.0);
        list.append(item);
    }
    return list;
}

void BillModel::importXlsx(const QUrl &url) {
    if (m_importing) return;
    m_cancelFlag.storeRelease(0);

    QString path = url.toLocalFile();
    QFileInfo fi(path);
    if (!fi.exists()) {
        emit importDone(QStringLiteral("File not found"));
        return;
    }

    QString absPath = fi.absoluteFilePath();
    if (BillStorage::isFileAlreadyImported(absPath, fi.size(), fi.lastModified())) {
        emit importDone(QStringLiteral("File unchanged, skipped"));
        return;
    }

    m_importing = true;
    m_importStartTime = QDateTime::currentDateTime();
    emit importingChanged();

    auto future = QtConcurrent::run([this, path, absPath]() {
        QString err;
        QVector<BillRecord> records = BillParser::parseXlsx(path, {}, &err, &m_cancelFlag);
        if (m_cancelFlag.loadAcquire() != 0) {
            QMetaObject::invokeMethod(this, [this]() {
                m_importing = false;
                emit importingChanged();
                emit importDone(QStringLiteral("Import cancelled"));
            }, Qt::QueuedConnection);
            return;
        }

        QMetaObject::invokeMethod(this,
            [this, absPath, records = std::move(records), err]() mutable {
            if (!err.isEmpty()) {
                m_importing = false;
                emit importingChanged();
                emit importDone(QStringLiteral("Parse failed: ") + err);
                return;
            }

            QFileInfo fi(absPath);
            BillClassifier::classifyAll(records);

            QString importId = QUuid::createUuid().toString(QUuid::WithoutBraces);
            int skipped = 0;
            QString insertErr;
            int inserted = BillStorage::insertRecords(records, &skipped, &insertErr,
                                                      importId, fi.fileName(), absPath);

            if (!insertErr.isEmpty()) {
                m_importing = false;
                emit importingChanged();
                emit importDone(QStringLiteral("Insert failed: ") + insertErr);
                return;
            }

            BillStorage::markFileImported(absPath, fi.size(), fi.lastModified());

            setRecords(BillStorage::fetchAll());
            ++m_categoriesRevision;
            emit categoriesChanged();

            double sec = m_importStartTime.msecsTo(QDateTime::currentDateTime()) / 1000.0;
            m_importing = false;
            emit importingChanged();
            emit importDone(QStringLiteral("Imported %1, skipped %2, %3s")
                            .arg(inserted).arg(skipped).arg(sec, 0, 'f', 1));
        }, Qt::QueuedConnection);
    });
    Q_UNUSED(future)
}

QVariantList BillModel::categoryExpense(int days) const {
    QVariantList list;
    auto stats = BillStorage::categoryStats(days);
    for (const auto &p : stats) {
        QVariantMap m;
        m["category"] = p.first;
        m["amount"] = p.second;
        list.append(m);
    }
    return list;
}

QVariantList BillModel::monthlyExpense(int year) const {
    QVariantList list;
    auto stats = BillStorage::monthlyExpenseForYear(year);
    for (const auto &p : stats) {
        QVariantMap item;
        item["date"] = QString::number(p.first);
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

double BillModel::yearTotal(int year) const {
    double sum = 0;
    auto stats = BillStorage::monthlyExpenseForYear(year);
    for (const auto &p : stats) sum += p.second;
    return sum;
}

QVariantList BillModel::monthDailyExpense(int year, int month) const {
    QVariantList list;
    auto stats = BillStorage::dailyExpenseForMonth(year, month);
    for (const auto &p : stats) {
        QVariantMap item;
        item["date"] = QString::number(p.first);
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

double BillModel::monthDailyTotal(int year, int month) const {
    double sum = 0;
    auto stats = BillStorage::dailyExpenseForMonth(year, month);
    for (const auto &p : stats) sum += p.second;
    return sum;
}

QVariantList BillModel::topMerchants(int year, int month, int limit) const {
    QVariantList list;
    auto stats = BillStorage::topMerchants(year, month, limit);
    for (const auto &p : stats) {
        QVariantMap item;
        item["peer"] = p.first;
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

QVariantList BillModel::topMerchantsAll(int limit) const {
    QVariantList list;
    auto stats = BillStorage::topMerchantsAll(limit);
    for (const auto &p : stats) {
        QVariantMap item;
        item["peer"] = p.first;
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

double BillModel::totalExpenseAll() const {
    return BillStorage::totalExpenseAll();
}

bool BillModel::reloadForAccount(const QString &dbPath) {
    QString err;
    if (!BillStorage::init(dbPath, &err)) {
        qWarning() << "reload db failed:" << err;
        return false;
    }
    setRecords(BillStorage::fetchAll());
    ++m_categoriesRevision;
    emit categoriesChanged();
    return true;
}

QVariantList BillModel::yearlyForecast(int year, bool longModel) const {
    QVariantList result;
    auto history = BillStorage::monthlyTotals(36);
    if (history.isEmpty()) return result;

    auto forecast = longModel
        ? ForecastEngine::predictLong(history, year)
        : ForecastEngine::predictLight(history, year);

    for (const auto &f : forecast) {
        QVariantMap item;
        item["date"] = QString::number(f.month);
        item["amount"] = f.value;
        result.append(item);
    }
    return result;
}

bool BillModel::hasLongForecast() const {
    auto history = BillStorage::monthlyTotals(36);
    return ForecastEngine::hasEnoughForLong(history);
}

QVariantList BillModel::importHistoryList() const {
    QVariantList list;
    auto history = BillStorage::importHistory();
    for (const auto &h : history) {
        QVariantMap item;
        item["id"] = h.id;
        item["fileName"] = h.fileName;
        item["recordCount"] = h.recordCount;
        item["minTime"] = h.minTime;
        item["maxTime"] = h.maxTime;
        item["importTime"] = h.importTime;
        list.append(item);
    }
    return list;
}

int BillModel::totalBillCount() const {
    return BillStorage::totalBillCount();
}

bool BillModel::deleteImportHistory(qint64 id) {
    if (!BillStorage::deleteImport(id)) return false;
    setRecords(BillStorage::fetchAll());
    ++m_categoriesRevision;
    emit categoriesChanged();
    return true;
}

QVariantList BillModel::dailyNet(int days) const {
    QVariantList list;
    QDate end = QDate::currentDate();
    QDate start = end.addDays(-(days - 1));

    QStringList months;
    for (QDate d = start; d <= end; d = d.addDays(1)) {
        QString m = d.toString("yyyy-MM");
        if (!months.contains(m)) months << m;
    }

    auto summaries = BillStorage::summariesForMonths(months);
    QMap<QString, double> byDate;
    for (const auto &s : summaries) {
        QString key = s.yearMonth + "-" + QString("%1").arg(s.day, 2, 10, QChar('0'));
        byDate[key] = s.income - s.expense;
    }

    for (QDate d = start; d <= end; d = d.addDays(1)) {
        QVariantMap item;
        item["date"] = d.toString("MM-dd");
        item["amount"] = byDate.value(d.toString("yyyy-MM-dd"), 0.0);
        list.append(item);
    }
    return list;
}

QVariantList BillModel::monthDailyNet(int year, int month) const {
    QVariantList list;
    auto stats = BillStorage::dailyNetForMonth(year, month);
    for (const auto &p : stats) {
        QVariantMap item;
        item["date"] = QString::number(p.first);
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

QVariantList BillModel::monthlyNet(int year) const {
    QVariantList list;
    auto stats = BillStorage::monthlyNetForYear(year);
    for (const auto &p : stats) {
        QVariantMap item;
        item["date"] = QString::number(p.first);
        item["amount"] = p.second;
        list.append(item);
    }
    return list;
}

void BillModel::cancelImport() {
    m_cancelFlag.storeRelease(1);
}