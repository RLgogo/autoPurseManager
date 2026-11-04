#include "billclassifier.h"
#include "billstorage.h"
#include "categoryrules.h"

QString BillClassifier::classify(const BillRecord &r) {
    // 1. 学习表精确匹配 (peer, product)
    QString c = BillStorage::learnedCategory(r.peer, r.product);
    if (!c.isEmpty()) return c;

    // 2. 预设关键词
    return CategoryRules::classify(r.peer, r.product, r.type, r.note);
}

void BillClassifier::classifyAll(QVector<BillRecord> &records) {
    for (auto &r : records) {
        if (r.category.isEmpty())
            r.category = classify(r);
    }
}