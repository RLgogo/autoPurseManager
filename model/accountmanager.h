#pragma once
#include <QObject>
#include <QString>
#include <QVector>
#include <QVariantList>

struct AccountInfo {
    QString id;
    QString name;
};

class AccountManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList accounts READ accountsList NOTIFY accountsChanged)
    Q_PROPERTY(QString currentId READ currentId NOTIFY currentChanged)
    Q_PROPERTY(int count READ count NOTIFY accountsChanged)
    Q_PROPERTY(int maxAccounts READ maxAccounts CONSTANT)

public:
    explicit AccountManager(QObject *parent = nullptr);

    bool init();

    QVariantList accountsList() const;
    QString currentId() const;
    int count() const;
    int maxAccounts() const { return 5; }

    Q_INVOKABLE QString createAccount(const QString &name);
    Q_INVOKABLE QString login(const QString &id);
    Q_INVOKABLE bool removeAccount(const QString &id);
    Q_INVOKABLE bool renameAccount(const QString &id, const QString &newName);

signals:
    void accountsChanged();
    void currentChanged();

private:
    QString m_configPath;
    QVector<AccountInfo> m_accounts;
    QString m_currentId;

    bool loadConfig();
    bool saveConfig();
    QString accountDirFor(const QString &id) const;
    QString dbPathForAccount(const QString &id) const;
    QString newAccountId() const;
};