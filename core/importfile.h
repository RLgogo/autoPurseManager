#pragma once

#include <QAtomicInt>
#include <QDateTime>
#include <QString>
#include <QUrl>

// 账单文件来源适配：把 QML FileDialog 给出的 URL 统一成“可读的本地文件”。
// Windows/macOS/Linux 上 FileDialog 返回 file:// URL；Android 上返回
// content:// URI，QXlsx 无法直接读取，需要先复制到应用缓存目录。
namespace ImportFile {

struct Source {
    QString path;          // 本地可读路径；content URI 在 materialize() 后指向缓存副本
    QString displayName;   // 原始文件名，用于导入历史展示
    QString key;           // 去重键：本地绝对路径或 content URI
    qint64 size = -1;
    QDateTime modified;
    bool local = true;
    bool temporary = false; // path 是否为本次复制出来的临时文件
};

// 解析并校验 URL，不复制文件，可在主线程调用。
// 失败时返回 false，并把面向用户的错误写入 error。
bool inspect(const QUrl &url, Source *source, QString *error);

// 若 source 不是本地文件，则流式复制到应用缓存；成功后可安全交给 QXlsx。
// 可在工作线程调用；cancel 非空时会在复制过程中响应取消。
bool materialize(Source *source, QString *error, const QAtomicInt *cancel = nullptr);

// 删除 materialize() 产生的临时副本。
void discard(const Source &source);

} // namespace ImportFile
