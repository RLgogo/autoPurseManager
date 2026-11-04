#pragma once
#include "core/billrecord.h"
#include <QAbstractListModel>
#include <QVector>
#include <QVariantList>
#include <QDateTime>
#include <QUrl>

class BillModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int categoriesRevision READ categoriesRevision NOTIFY categoriesChanged)
    Q_PROPERTY(bool importing READ importing NOTIFY importingChanged)

public:
    enum Roles {
        TimeRole = Qt::UserRole + 1,
        PeerRole,
        DirectionRole,
        AmountRole
    };

    explicit BillModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRecords(const QVector<BillRecord> &records);
    Q_INVOKABLE int count() const { return m_records.size(); }
    Q_INVOKABLE double todayExpense() const;
    Q_INVOKABLE double monthExpense() const;
    Q_INVOKABLE QVariantList dailyExpense(int days) const;
    Q_INVOKABLE QVariantList categoryExpense(int days) const;
    Q_INVOKABLE QVariantList monthlyExpense(int year) const;
    Q_INVOKABLE double yearTotal(int year) const;
    Q_INVOKABLE QVariantList monthDailyExpense(int year, int month) const;
    Q_INVOKABLE double monthDailyTotal(int year, int month) const;
    Q_INVOKABLE QVariantList topMerchants(int year, int month, int limit) const;
    Q_INVOKABLE QVariantList topMerchantsAll(int limit) const;
    Q_INVOKABLE double totalExpenseAll() const;

    Q_INVOKABLE void importXlsx(const QUrl &url);
    bool importing() const { return m_importing; }

    Q_INVOKABLE QVariantList importHistoryList() const;
    Q_INVOKABLE int totalBillCount() const;
    Q_INVOKABLE bool deleteImportHistory(qint64 id);

    Q_INVOKABLE QVariantList dailyNet(int days) const;
    Q_INVOKABLE QVariantList monthDailyNet(int year, int month) const;
    Q_INVOKABLE QVariantList monthlyNet(int year) const;

    Q_INVOKABLE void cancelImport();

    Q_INVOKABLE bool reloadForAccount(const QString &dbPath);
    Q_INVOKABLE void clear() {
        beginResetModel();
        m_records.clear();
        endResetModel();
        ++m_categoriesRevision;
        emit categoriesChanged();
    }

    int categoriesRevision() const { return m_categoriesRevision; }

    Q_INVOKABLE QVariantList yearlyForecast(int year, bool longModel) const;
    Q_INVOKABLE bool hasLongForecast() const;

signals:
    void categoriesChanged();
    void importingChanged();
    void importDone(const QString &message);

private:
    QVector<BillRecord> m_records;
    int m_categoriesRevision = 0;
    bool m_importing = false;
    QDateTime m_importStartTime;
    QAtomicInt m_cancelFlag{0};
};