#include "languagemanager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

LanguageManager::LanguageManager(QObject *parent) : QObject(parent) {
    loadTranslations();
    applyTexts();
}

void LanguageManager::loadTranslations() {
    QFile f(":/translations.json");
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "translations.json not found";
        return;
    }
    auto doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    if (!doc.isObject()) return;
    auto root = doc.object();
    m_en = root.value("en").toObject().toVariantMap();
    m_zh = root.value("zh").toObject().toVariantMap();
}

void LanguageManager::applyTexts() {
    m_texts = (m_currentLang == "zh") ? m_zh : m_en;
    m_tips = m_texts.value("tips").toList();
    emit textsChanged();
    emit tipsChanged();
}

void LanguageManager::setLanguage(const QString &lang) {
    QString normalized = (lang == "zh") ? "zh" : "en";
    if (normalized == m_currentLang) return;
    m_currentLang = normalized;
    applyTexts();
    emit currentLangChanged();
}