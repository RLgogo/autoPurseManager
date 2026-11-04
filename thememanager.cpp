#include "thememanager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSettings>
#include <QDebug>

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
    loadThemes();

    QSettings settings("RL", "autoPurseManager");
    QString savedId = settings.value("theme/id", "light_mono").toString();

    if (m_themesById.contains(savedId)) {
        m_currentId = savedId;
    } else if (m_themesById.contains("light_mono")) {
        m_currentId = "light_mono";
    } else if (!m_available.isEmpty()) {
        m_currentId = m_available.first().toMap()["id"].toString();
    }

    if (m_themesById.contains(m_currentId))
        m_current = m_themesById[m_currentId].toMap();
}

void ThemeManager::loadThemes() {
    QFile f(":/themes.json");
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "themes.json not found";
        return;
    }
    auto doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    if (!doc.isObject()) return;
    auto arr = doc.object().value("themes").toArray();
    for (const auto &v : arr) {
        auto obj = v.toObject();
        QString id = obj.value("id").toString();
        m_themesById[id] = obj.toVariantMap();
        QVariantMap item;
        item["id"] = id;
        item["name"] = obj.value("name").toString();
        item["bg"] = obj.value("bg").toString();
        item["card"] = obj.value("card").toString();
        item["text"] = obj.value("text").toString();
        item["accent"] = obj.value("accent").toString();
        m_available.append(item);
    }
}

void ThemeManager::setTheme(const QString &id) {
    if (!m_themesById.contains(id)) return;
    if (id == m_currentId) return;
    m_currentId = id;
    m_current = m_themesById[id].toMap();

    QSettings settings("RL", "autoPurseManager");
    settings.setValue("theme/id", id);

    emit themeChanged();
}