#pragma once
#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QString>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentThemeId READ currentThemeId NOTIFY themeChanged)
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(QVariantList availableThemes READ availableThemes NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    QString currentThemeId() const { return m_currentId; }
    QVariantMap theme() const { return m_current; }
    QVariantList availableThemes() const { return m_available; }

    Q_INVOKABLE void setTheme(const QString &id);

signals:
    void themeChanged();

private:
    void loadThemes();
    QString m_currentId = "light_mono";
    QVariantMap m_current;
    QVariantList m_available;
    QVariantMap m_themesById;
};