#pragma once
#include "billrecord.h"
#include <QVector>

class BillClassifier {
public:
    static QString classify(const BillRecord &r);
    static void classifyAll(QVector<BillRecord> &records);
};