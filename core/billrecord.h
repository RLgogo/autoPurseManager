#pragma once
#include <Qstring>
#include <QDateTime>

struct BillRecord
{
    QDateTime time;
    QString type;
    QString peer;
    QString product;
    QString direction;
    double amount=0.0;
    QString status;
    QString tradeNo;
    QString merchantNo;
    QString note;
    QString category;
    /* data */
};
