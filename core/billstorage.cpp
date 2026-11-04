#include "billstorage.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDateTime>

static QSqlDatabase db() {
    return QSqlDatabase::database("bills");
}

bool BillStorage::init(const QString &dbPath, QString *error) {
    if (QSqlDatabase::contains("bills")) {
        {
            QSqlDatabase old = QSqlDatabase::database("bills");
            if (old.isOpen()) old.close();
        }
        QSqlDatabase::removeDatabase("bills");
    }

    QSqlDatabase d = QSqlDatabase::addDatabase("QSQLITE", "bills");
    d.setDatabaseName(dbPath);
    if (!d.open()) {
        if (error) {
            QSqlError e = d.lastError();
            *error = QString("text=[%1] db=[%2] driver=[%3] path=%4")
                         .arg(e.text(), e.databaseText(), e.driverText(), dbPath);
        }
        return false;
    }

    QSqlQuery q(d);

    bool ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time TEXT NOT NULL,
            type TEXT,
            peer TEXT,
            product TEXT,
            direction TEXT,
            amount REAL,
            status TEXT,
            trade_no TEXT,
            merchant_no TEXT,
            note TEXT,
            import_time TEXT,
            category TEXT DEFAULT '',
            import_id TEXT DEFAULT '',
            UNIQUE(time, amount, peer, trade_no)
        )
    )");
    if (!ok) {
        if (error) *error = q.lastError().text();
        return false;
    }

    q.exec("ALTER TABLE bills ADD COLUMN category TEXT DEFAULT ''");
    q.exec("ALTER TABLE bills ADD COLUMN import_id TEXT DEFAULT ''");

    bool ok2 = q.exec(R"(
        CREATE TABLE IF NOT EXISTS import_log (
            file_path TEXT PRIMARY KEY,
            file_size INTEGER,
            file_mtime TEXT,
            imported_at TEXT
        )
    )");
    if (!ok2) {
        if (error) *error = q.lastError().text();
        return false;
    }

    bool ok3 = q.exec(R"(
        CREATE TABLE IF NOT EXISTS daily_summary (
            year_month TEXT NOT NULL,
            day INTEGER NOT NULL,
            expense REAL NOT NULL DEFAULT 0,
            income REAL NOT NULL DEFAULT 0,
            PRIMARY KEY (year_month, day)
        )
    )");
    if (!ok3) {
        if (error) *error = q.lastError().text();
        return false;
    }

    bool ok4 = q.exec(R"(
        CREATE TABLE IF NOT EXISTS import_meta (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    )");
    if (!ok4) {
        if (error) *error = q.lastError().text();
        return false;
    }

    bool okRule = q.exec(R"(
        CREATE TABLE IF NOT EXISTS learned_rules (
            peer TEXT NOT NULL,
            product TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL,
            updated_at TEXT,
            PRIMARY KEY (peer, product)
        )
    )");
    if (!okRule) {
        if (error) *error = q.lastError().text();
        return false;
    }

    bool okHist = q.exec(R"(
        CREATE TABLE IF NOT EXISTS import_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            import_id TEXT NOT NULL,
            file_name TEXT,
            file_path TEXT DEFAULT '',
            record_count INTEGER,
            min_time TEXT,
            max_time TEXT,
            import_time TEXT
        )
    )");
    if (!okHist) {
        if (error) *error = q.lastError().text();
        return false;
    }

    q.exec("ALTER TABLE import_history ADD COLUMN file_path TEXT DEFAULT ''");

    return true;
}

int BillStorage::insertRecords(const QVector<BillRecord> &records,
                               int *skipped, QString *error,
                               const QString &importId, const QString &fileName,
                               const QString &filePath) {
    QSqlDatabase d = db();
    if (!d.isOpen()) {
        if (error) *error = "database not open";
        return 0;
    }

    d.transaction();
    QSqlQuery q(d);
    q.prepare(R"(
        INSERT OR IGNORE INTO bills
        (time, type, peer, product, direction, amount, status,
         trade_no, merchant_no, note, import_time, category, import_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    )");

    int inserted = 0, dup = 0;
    QSet<QString> affectedMonths;
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QDateTime minTime, maxTime;

    for (const auto &r : records) {
        q.addBindValue(r.time.toString(Qt::ISODateWithMs));
        q.addBindValue(r.type);
        q.addBindValue(r.peer);
        q.addBindValue(r.product);
        q.addBindValue(r.direction);
        q.addBindValue(r.amount);
        q.addBindValue(r.status);
        q.addBindValue(r.tradeNo);
        q.addBindValue(r.merchantNo);
        q.addBindValue(r.note);
        q.addBindValue(now);
        q.addBindValue(r.category);
        q.addBindValue(importId);
        if (q.exec()) {
            if (q.numRowsAffected() > 0) {
                ++inserted;
                affectedMonths.insert(r.time.toString("yyyy-MM"));
                if (!minTime.isValid() || r.time < minTime) minTime = r.time;
                if (!maxTime.isValid() || r.time > maxTime) maxTime = r.time;
            } else {
                ++dup;
            }
        } else {
            if (error) *error = q.lastError().text();
        }
    }
    d.commit();
    if (inserted > 0 && !records.isEmpty()) {
        QDateTime maxTime;
        for (const auto &r : records) {
            if (r.time.isValid() && (!maxTime.isValid() || r.time > maxTime))
                maxTime = r.time;
        }
        if (maxTime.isValid())
            setLastMaxTime(maxTime);
    }

    for (const auto &m : affectedMonths)
        refreshMonthSummary(m);

    if (!importId.isEmpty() && inserted > 0) {
        QSqlQuery h(db());
        h.prepare("INSERT INTO import_history "
                  "(import_id, file_name, file_path, record_count, min_time, max_time, import_time) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?)");
        h.addBindValue(importId);
        h.addBindValue(fileName);
        h.addBindValue(filePath);
        h.addBindValue(inserted);
        h.addBindValue(minTime.toString(Qt::ISODateWithMs));
        h.addBindValue(maxTime.toString(Qt::ISODateWithMs));
        h.addBindValue(now);
        h.exec();
    }

    if (skipped) *skipped = dup;
    return inserted;
}

int BillStorage::totalCount(QString *error) {
    QSqlQuery q(db());
    if (!q.exec("SELECT COUNT(*) FROM bills") || !q.next()) {
        if (error) *error = q.lastError().text();
        return -1;
    }
    return q.value(0).toInt();
}

QVector<BillRecord> BillStorage::fetchAll(QString *error) {
    QVector<BillRecord> result;
    if (!db().isOpen()) return {};
    QSqlQuery q(db());
    if (!q.exec("SELECT time, type, peer, product, direction, amount, "
                "status, trade_no, merchant_no, note, category FROM bills "
                "ORDER BY time DESC LIMIT 2000")) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        BillRecord r;
        r.time       = QDateTime::fromString(q.value(0).toString(), Qt::ISODateWithMs);
        r.type       = q.value(1).toString();
        r.peer       = q.value(2).toString();
        r.product    = q.value(3).toString();
        r.direction  = q.value(4).toString();
        r.amount     = q.value(5).toDouble();
        r.status     = q.value(6).toString();
        r.tradeNo    = q.value(7).toString();
        r.merchantNo = q.value(8).toString();
        r.note       = q.value(9).toString();
         r.category   = q.value(10).toString();
        result.append(r);
    }
    return result;
}

bool BillStorage::isFileAlreadyImported(const QString &path, qint64 size,
                                        const QDateTime &mtime) {
    if (!db().isOpen()) return false;
    QSqlQuery q(db());
    q.prepare("SELECT file_size, file_mtime FROM import_log WHERE file_path = ?");
    q.addBindValue(path);
    if (!q.exec() || !q.next()) return false;
    return q.value(0).toLongLong() == size
        && q.value(1).toString() == mtime.toString(Qt::ISODate);
}

void BillStorage::markFileImported(const QString &path, qint64 size,
                                   const QDateTime &mtime) {
    QSqlQuery q(db());
    q.prepare("INSERT OR REPLACE INTO import_log "
              "(file_path, file_size, file_mtime, imported_at) "
              "VALUES (?, ?, ?, ?)");
    q.addBindValue(path);
    q.addBindValue(size);
    q.addBindValue(mtime.toString(Qt::ISODate));
    q.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));
    q.exec();
}

void BillStorage::rebuildAllSummaries(QString *error) {
    QSqlQuery del(db());
    if (!del.exec("DELETE FROM daily_summary")) {
        if (error) *error = del.lastError().text();
        return;
    }

    QSqlQuery q(db());
    bool ok = q.exec(R"(
        INSERT INTO daily_summary (year_month, day, expense, income)
        SELECT substr(time,1,7),
               CAST(substr(time,9,2) AS INTEGER),
               SUM(CASE WHEN direction='支出' THEN amount ELSE 0 END),
               SUM(CASE WHEN direction='收入' THEN amount ELSE 0 END)
        FROM bills
        GROUP BY substr(time,1,7), substr(time,9,2)
    )");
    if (!ok && error) *error = q.lastError().text();
}

void BillStorage::refreshMonthSummary(const QString &yearMonth, QString *error) {
    QSqlQuery del(db());
    del.prepare("DELETE FROM daily_summary WHERE year_month = ?");
    del.addBindValue(yearMonth);
    if (!del.exec()) {
        if (error) *error = del.lastError().text();
        return;
    }

    QSqlQuery q(db());
    q.prepare(R"(
        INSERT INTO daily_summary (year_month, day, expense, income)
        SELECT substr(time,1,7),
               CAST(substr(time,9,2) AS INTEGER),
               SUM(CASE WHEN direction='支出' THEN amount ELSE 0 END),
               SUM(CASE WHEN direction='收入' THEN amount ELSE 0 END)
        FROM bills
        WHERE substr(time,1,7) = ?
        GROUP BY substr(time,9,2)
    )");
    q.addBindValue(yearMonth);
    if (!q.exec() && error) *error = q.lastError().text();
}

QVector<BillStorage::DailySummary>
BillStorage::summariesForMonths(const QStringList &yearMonths, QString *error) {
    QVector<DailySummary> result;
    if (!db().isOpen()) return {};
    if (yearMonths.isEmpty()) return result;

    QStringList placeholders;
    for (int i = 0; i < yearMonths.size(); ++i) placeholders << "?";
    QSqlQuery q(db());
    q.prepare(QString("SELECT year_month, day, expense, income "
                      "FROM daily_summary WHERE year_month IN (%1)")
                  .arg(placeholders.join(",")));
    for (const auto &m : yearMonths) q.addBindValue(m);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        DailySummary s;
        s.yearMonth = q.value(0).toString();
        s.day = q.value(1).toInt();
        s.expense = q.value(2).toDouble();
        s.income = q.value(3).toDouble();
        result.append(s);
    }
    return result;
}

QDateTime BillStorage::lastMaxTime() {
    if (!db().isOpen()) return {};
    QSqlQuery q(db());
    q.prepare("SELECT value FROM import_meta WHERE key = 'last_max_time'");
    if (!q.exec() || !q.next()) return {};
    return QDateTime::fromString(q.value(0).toString(), Qt::ISODateWithMs);
}

void BillStorage::setLastMaxTime(const QDateTime &time) {
    QSqlQuery q(db());
    q.prepare("INSERT OR REPLACE INTO import_meta (key, value) "
              "VALUES ('last_max_time', ?)");
    q.addBindValue(time.toString(Qt::ISODateWithMs));
    q.exec();
}

QString BillStorage::learnedCategory(const QString &peer, const QString &product) {
    if (!db().isOpen()) return {};
    QSqlQuery q(db());
    q.prepare("SELECT category FROM learned_rules "
              "WHERE peer = ? AND product = ?");
    q.addBindValue(peer);
    q.addBindValue(product);
    if (q.exec() && q.next())
        return q.value(0).toString();

    q.prepare("SELECT category FROM learned_rules "
              "WHERE peer = ? AND product = ''");
    q.addBindValue(peer);
    if (q.exec() && q.next())
        return q.value(0).toString();

    return {};
}

void BillStorage::learnCategory(const QString &peer, const QString &product,
                                const QString &category) {
    QSqlQuery q(db());
    q.prepare("INSERT OR REPLACE INTO learned_rules "
              "(peer, product, category, updated_at) VALUES (?, ?, ?, ?)");
    q.addBindValue(peer);
    q.addBindValue(product);
    q.addBindValue(category);
    q.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));
    q.exec();
}

QVector<QPair<QString, double>>
BillStorage::categoryStats(int days, QString *error) {
    QVector<QPair<QString, double>> result;
    if (!db().isOpen()) return {};
    QDate start = QDate::currentDate().addDays(-(days - 1));
    QSqlQuery q(db());
    q.prepare("SELECT category, SUM(amount) FROM bills "
              "WHERE direction = '支出' AND time >= ? "
              "GROUP BY category ORDER BY SUM(amount) DESC");
    q.addBindValue(start.toString("yyyy-MM-dd") + "T00:00:00.000");
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        QString cat = q.value(0).toString();
        if (cat.isEmpty()) cat = "其他";
        result.append({cat, q.value(1).toDouble()});
    }
    return result;
}

QVector<QPair<int, double>>
BillStorage::monthlyExpenseForYear(int year, QString *error) {
    QVector<QPair<int, double>> result;
    if (!db().isOpen()) return {};
    for (int m = 1; m <= 12; ++m)
        result.append({m, 0.0});

    QSqlQuery q(db());
    q.prepare("SELECT CAST(substr(year_month, 6, 2) AS INTEGER), SUM(expense) "
              "FROM daily_summary WHERE year_month LIKE ? GROUP BY year_month");
    q.addBindValue(QString::number(year) + "-%");
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        int m = q.value(0).toInt();
        double v = q.value(1).toDouble();
        if (m >= 1 && m <= 12)
            result[m - 1].second = v;
    }
    return result;
}

QVector<QPair<int, double>>
BillStorage::dailyExpenseForMonth(int year, int month, QString *error) {
    QVector<QPair<int, double>> result;
    if (!db().isOpen()) return {};
    int days = QDate(year, month, 1).daysInMonth();
    for (int d = 1; d <= days; ++d)
        result.append({d, 0.0});

    QString ym = QString("%1-%2").arg(year).arg(month, 2, 10, QChar('0'));
    QSqlQuery q(db());
    q.prepare("SELECT day, expense FROM daily_summary WHERE year_month = ?");
    q.addBindValue(ym);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        int d = q.value(0).toInt();
        double v = q.value(1).toDouble();
        if (d >= 1 && d <= days)
            result[d - 1].second = v;
    }
    return result;
}

QVector<QPair<QString, double>>
BillStorage::topMerchants(int year, int month, int limit, QString *error) {
    QVector<QPair<QString, double>> result;
    if (!db().isOpen()) return {};
    QString ym = QString("%1-%2").arg(year).arg(month, 2, 10, QChar('0'));

    QSqlQuery q(db());
    q.prepare("SELECT peer, SUM(amount) AS s FROM bills "
              "WHERE direction = '支出' AND substr(time, 1, 7) = ? "
              "GROUP BY peer ORDER BY s DESC LIMIT ?");
    q.addBindValue(ym);
    q.addBindValue(limit);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        result.append({q.value(0).toString(), q.value(1).toDouble()});
    }
    return result;
}

QVector<QPair<QString, double>>
BillStorage::topMerchantsAll(int limit, QString *error) {
    QVector<QPair<QString, double>> result;
    if (!db().isOpen()) return {};
    QSqlQuery q(db());
    q.prepare("SELECT peer, SUM(amount) AS s FROM bills "
              "WHERE direction = '支出' "
              "GROUP BY peer ORDER BY s DESC LIMIT ?");
    q.addBindValue(limit);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        result.append({q.value(0).toString(), q.value(1).toDouble()});
    }
    return result;
}

double BillStorage::totalExpenseAll(QString *error) {
    if (!db().isOpen()) return 0;
    QSqlQuery q(db());
    if (!q.exec("SELECT SUM(amount) FROM bills WHERE direction = '支出'")
        || !q.next()) {
        if (error) *error = q.lastError().text();
        return 0;
    }
    return q.value(0).toDouble();
}

QVector<QPair<QString, double>>
BillStorage::monthlyTotals(int months, QString *error) {
    QVector<QPair<QString, double>> result;
    if (!db().isOpen()) return {};
    if (!db().isOpen()) return result;

    QSqlQuery q(db());
    q.prepare("SELECT year_month, SUM(expense) FROM daily_summary "
              "GROUP BY year_month ORDER BY year_month DESC LIMIT ?");
    q.addBindValue(months);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        result.prepend({q.value(0).toString(), q.value(1).toDouble()});
    }
    return result;
}

QVector<BillStorage::ImportHistory>
BillStorage::importHistory(QString *error) {
    QVector<ImportHistory> result;
    if (!db().isOpen()) return result;

    QSqlQuery q(db());
    if (!q.exec("SELECT id, import_id, file_name, file_path, record_count, min_time, max_time, import_time "
                "FROM import_history ORDER BY id DESC")) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        ImportHistory h;
        h.id = q.value(0).toLongLong();
        h.importId = q.value(1).toString();
        h.fileName = q.value(2).toString();
        h.filePath = q.value(3).toString();
        h.recordCount = q.value(4).toInt();
        h.minTime = q.value(5).toString();
        h.maxTime = q.value(6).toString();
        h.importTime = q.value(7).toString();
        result.append(h);
    }
    return result;
}

int BillStorage::totalBillCount(QString *error) {
    if (!db().isOpen()) return 0;
    QSqlQuery q(db());
    if (!q.exec("SELECT COUNT(*) FROM bills") || !q.next()) {
        if (error) *error = q.lastError().text();
        return 0;
    }
    return q.value(0).toInt();
}

bool BillStorage::deleteImport(qint64 historyId, QString *error) {
    if (!db().isOpen()) return false;

    QSqlQuery q(db());
    q.prepare("SELECT import_id, file_name, file_path "
              "FROM import_history WHERE id = ?");
    q.addBindValue(historyId);
    if (!q.exec() || !q.next()) {
        if (error) *error = "history not found";
        return false;
    }
    QString importId = q.value(0).toString();
    QString fileName = q.value(1).toString();
    QString filePath = q.value(2).toString();
    if (importId.isEmpty()) return false;

    QSqlDatabase d = db();
    d.transaction();

    QSqlQuery del1(d);
    del1.prepare("DELETE FROM bills WHERE import_id = ?");
    del1.addBindValue(importId);
    if (!del1.exec()) {
        if (error) *error = del1.lastError().text();
        d.rollback();
        return false;
    }

    QSqlQuery del2(d);
    del2.prepare("DELETE FROM import_history WHERE id = ?");
    del2.addBindValue(historyId);
    if (!del2.exec()) {
        if (error) *error = del2.lastError().text();
        d.rollback();
        return false;
    }

    QSqlQuery del3(d);
    if (!filePath.isEmpty()) {
        del3.prepare("DELETE FROM import_log WHERE file_path = ?");
        del3.addBindValue(filePath);
    } else if (!fileName.isEmpty()) {
        QString escaped = fileName;
        escaped.replace("\\", "\\\\");
        escaped.replace("%", "\\%");
        escaped.replace("_", "\\_");
        del3.prepare("DELETE FROM import_log WHERE file_path LIKE ? ESCAPE '\\'");
        del3.addBindValue("%" + escaped);
    }
    if (!del3.exec()) {
        if (error) *error = del3.lastError().text();
        d.rollback();
        return false;
    }

    d.commit();

    rebuildAllSummaries(error);
    return true;
}

QVector<QPair<int, double>>
BillStorage::dailyNetForMonth(int year, int month, QString *error) {
    QVector<QPair<int, double>> result;
    if (!db().isOpen()) return result;

    int days = QDate(year, month, 1).daysInMonth();
    for (int d = 1; d <= days; ++d)
        result.append({d, 0.0});

    QString ym = QString("%1-%2").arg(year).arg(month, 2, 10, QChar('0'));
    QSqlQuery q(db());
    q.prepare("SELECT day, income - expense FROM daily_summary WHERE year_month = ?");
    q.addBindValue(ym);
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        int d = q.value(0).toInt();
        double v = q.value(1).toDouble();
        if (d >= 1 && d <= days)
            result[d - 1].second = v;
    }
    return result;
}

QVector<QPair<int, double>>
BillStorage::monthlyNetForYear(int year, QString *error) {
    QVector<QPair<int, double>> result;
    if (!db().isOpen()) return result;

    for (int m = 1; m <= 12; ++m)
        result.append({m, 0.0});

    QSqlQuery q(db());
    q.prepare("SELECT CAST(substr(year_month, 6, 2) AS INTEGER), "
              "SUM(income - expense) "
              "FROM daily_summary WHERE year_month LIKE ? GROUP BY year_month");
    q.addBindValue(QString::number(year) + "-%");
    if (!q.exec()) {
        if (error) *error = q.lastError().text();
        return result;
    }
    while (q.next()) {
        int m = q.value(0).toInt();
        double v = q.value(1).toDouble();
        if (m >= 1 && m <= 12)
            result[m - 1].second = v;
    }
    return result;
}