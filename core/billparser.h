#pragma once
#include "billrecord.h"
#include <QString>
#include <QVector>
#include <QDateTime>
#include <QAtomicInt>

class BillParser {
public:
    static QVector<BillRecord> parseXlsx(const QString &path,
                                         const QDateTime &stopAtTime = {},
                                         QString *error = nullptr,
                                         QAtomicInt *cancelFlag = nullptr);
};