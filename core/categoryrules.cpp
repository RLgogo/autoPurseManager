#include "categoryrules.h"
#include <QVector>

namespace {

struct RuleGroup {
    QString category;
    QStringList keywords;
};

const QVector<RuleGroup> &rules() {
    static const QVector<RuleGroup> r = {
        { "餐饮", {
            "美团外卖", "饿了么", "麦当劳", "肯德基", "星巴克", "瑞幸",
            "蜜雪冰城", "海底捞", "喜茶", "奈雪", "茶百道", "古茗",
            "华莱士", "沙县", "兰州拉面", "食堂", "餐厅", "饭店",
            "烧烤", "火锅", "咖啡", "奶茶", "面馆", "小吃"
        }},
        { "电商购物", {
            "美团买菜", "美团优选", "淘宝", "天猫", "京东", "拼多多",
            "唯品会", "苏宁", "盒马", "山姆", "沃尔玛", "超市",
            "便利店", "名创优品", "天猫超市", "买菜", "购物"
        }},
        { "生活缴费", {
            "电费", "水费", "燃气", "煤气", "国家电网", "网上国网",
            "南方电网", "物业", "话费", "宽带", "中国移动", "中国电信",
            "中国联通", "自来水", "供暖", "缴费"
        }},
        { "交通出行", {
            "滴滴", "高德", "曹操", "T3", "地铁", "公交", "加油",
            "停车", "高铁", "12306", "中国石油", "中国石化",
            "中石化", "中石油", "出租车", "共享单车", "哈啰",
            "美团单车", "青桔"
        }},
        { "娱乐充值", {
            "王者荣耀", "和平精英", "腾讯游戏", "网易游戏", "米哈游",
            "原神", "崩坏", "Steam", "Epic", "爱奇艺", "腾讯视频",
            "优酷", "芒果TV", "哔哩哔哩", "B站", "抖音", "快手",
            "会员", "充值", "点券", "游戏", "KTV", "电影", "影院",
            "猫眼", "淘票票"
        }},
        { "医疗健康", {
            "美团买药", "医院", "药房", "药店", "诊所", "体检",
            "挂号", "大药房", "医药"
        }}
    };
    return r;
}

} // namespace

QStringList CategoryRules::allCategories() {
    return { "餐饮", "电商购物", "生活缴费", "交通出行",
             "人情往来", "娱乐充值", "医疗健康", "其他" };
}

QString CategoryRules::matchBest(const QString &text) {
    if (text.isEmpty()) return {};
    QString bestCat;
    int bestLen = 0;
    for (const auto &g : rules()) {
        for (const auto &kw : g.keywords) {
            if (text.contains(kw, Qt::CaseInsensitive) && kw.length() > bestLen) {
                bestLen = kw.length();
                bestCat = g.category;
            }
        }
    }
    return bestCat;
}

QString CategoryRules::classify(const QString &peer, const QString &product,
                                const QString &type, const QString &note) {
    // 1. 备注优先（用户主动写的）
    QString c = matchBest(note);
    if (!c.isEmpty()) return c;

    // 2. 对方 + 商品联合匹配（长词优先，能区分"美团外卖"和"美团买菜"）
    c = matchBest(peer + " " + product);
    if (!c.isEmpty()) return c;

    // 3. 交易类型兜底
    if (type.contains("红包") || type.contains("转账"))
        return "人情往来";

    return "其他";
}