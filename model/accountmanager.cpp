#include "accountmanager.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>
#include <QDebug>

static QString appDataDir() {
    QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir;
}

AccountManager::AccountManager(QObject *parent) : QObject(parent) {
    m_configPath = appDataDir() + "/accounts.json";
}

bool AccountManager::init() {
    QDir().mkpath(appDataDir() + "/accounts");

    if (!loadConfig()) {
        AccountInfo def;
        def.id = "default";
        def.name = "默认账户";
        m_accounts.clear();
        m_accounts.append(def);
        m_currentId = "default";
        QDir().mkpath(accountDirFor("default"));
        saveConfig();
    }
    return true;
}

QVariantList AccountManager::accountsList() const {
    QVariantList list;
    for (const auto &a : m_accounts) {
        QVariantMap m;
        m["id"] = a.id;
        m["name"] = a.name;
        list.append(m);
    }
    return list;
}

QString AccountManager::currentId() const { return m_currentId; }
int AccountManager::count() const { return m_accounts.size(); }

QString AccountManager::createAccount(const QString &name) {
    if (m_accounts.size() >= 5) return QString();
    QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) return QString();

    AccountInfo a;
    a.id = newAccountId();
    a.name = trimmed;
    m_accounts.append(a);
    QDir().mkpath(accountDirFor(a.id));
    saveConfig();
    emit accountsChanged();
    return a.id;
}

QString AccountManager::login(const QString &id) {
    for (const auto &a : m_accounts) {
        if (a.id == id) {
            m_currentId = id;
            saveConfig();
            emit currentChanged();
            return dbPathForAccount(id);
        }
    }
    return QString();
}

bool AccountManager::removeAccount(const QString &id) {
    if (m_accounts.size() <= 1) return false;
    if (id == "default") return false;
    for (int i = 0; i < m_accounts.size(); ++i) {
        if (m_accounts[i].id == id) {
            m_accounts.remove(i);
            QDir(accountDirFor(id)).removeRecursively();
            if (m_currentId == id) m_currentId = "default";
            saveConfig();
            emit accountsChanged();
            return true;
        }
    }
    return false;
}

bool AccountManager::loadConfig() {
    QFile f(m_configPath);
    if (!f.exists()) return false;
    if (!f.open(QIODevice::ReadOnly)) return false;
    auto doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    if (!doc.isObject()) return false;
    auto obj = doc.object();
    m_currentId = obj.value("current").toString();
    m_accounts.clear();
    auto arr = obj.value("accounts").toArray();
    for (const auto &v : arr) {
        auto o = v.toObject();
        AccountInfo a;
        a.id = o.value("id").toString();
        a.name = o.value("name").toString();
        if (!a.id.isEmpty()) m_accounts.append(a);
    }
    return !m_accounts.isEmpty();
}

bool AccountManager::saveConfig() {
    QJsonObject obj;
    obj["current"] = m_currentId;
    QJsonArray arr;
    for (const auto &a : m_accounts) {
        QJsonObject o;
        o["id"] = a.id;
        o["name"] = a.name;
        arr.append(o);
    }
    obj["accounts"] = arr;
    QFile f(m_configPath);
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write(QJsonDocument(obj).toJson());
    f.close();
    return true;
}

QString AccountManager::accountDirFor(const QString &id) const {
    return appDataDir() + "/accounts/" + id;
}

QString AccountManager::dbPathForAccount(const QString &id) const {
    return accountDirFor(id) + "/bills.db";
}

QString AccountManager::newAccountId() const {
    return QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
}

bool AccountManager::renameAccount(const QString &id, const QString &newName) {
    QString trimmed = newName.trimmed();
    if (trimmed.isEmpty()) return false;
    for (auto &a : m_accounts) {
        if (a.id == id) {
            a.name = trimmed;
            saveConfig();
            emit accountsChanged();
            return true;
        }
    }
    return false;
}