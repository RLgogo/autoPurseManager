#pragma once
#include <QObject>
#include <QVariantMap>
#include <QString>

class LanguageManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLang READ currentLang NOTIFY currentLangChanged)
    Q_PROPERTY(QVariantMap texts READ texts NOTIFY textsChanged)
    Q_PROPERTY(QVariantList tips READ tips NOTIFY tipsChanged)

public:
    explicit LanguageManager(QObject *parent = nullptr);

    QString currentLang() const { return m_currentLang; }
    QVariantMap texts() const { return m_texts; }
    QVariantList tips() const { return m_tips; }

    Q_INVOKABLE void setLanguage(const QString &lang);

signals:
    void currentLangChanged();
    void textsChanged();
    void tipsChanged();

private:
    QString m_currentLang = "en";
    QVariantMap m_en;
    QVariantMap m_zh;
    QVariantMap m_texts;
    QVariantList m_tips;

    void loadTranslations();
    void applyTexts();
};