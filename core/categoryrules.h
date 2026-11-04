#pragma once
#include <QString>
#include <QStringList>

class CategoryRules {
public:
    static QStringList allCategories();
    static QString classify(const QString &peer, const QString &product,
                            const QString &type, const QString &note);

private:
    static QString matchBest(const QString &text);
};