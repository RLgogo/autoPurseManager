#include "importfile.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUuid>

namespace {

QString cacheDir() {
    QString base = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (base.isEmpty())
        base = QDir::tempPath() + QStringLiteral("/autoPurseManager");
    return base + QStringLiteral("/imports");
}

bool isCanceled(const QAtomicInt *cancel) {
    return cancel && cancel->loadAcquire() != 0;
}

} // namespace

bool ImportFile::inspect(const QUrl &url, Source *source, QString *error) {
    if (!source) return false;
    *source = Source();

    const QString scheme = url.scheme().toLower();
    if (url.isLocalFile() || scheme.isEmpty()) {
        const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString();
        const QFileInfo fi(path);
        if (!fi.exists() || !fi.isFile()) {
            if (error) *error = QStringLiteral("File not found");
            return false;
        }
        source->path = fi.absoluteFilePath();
        source->displayName = fi.fileName();
        source->key = source->path;
        source->size = fi.size();
        source->modified = fi.lastModified();
        source->local = true;
        return true;
    }

    if (scheme != QLatin1String("content")) {
        if (error) *error = QStringLiteral("Unsupported file URL: %1").arg(scheme);
        return false;
    }

    if (url.path().isEmpty()) {
        if (error) *error = QStringLiteral("Invalid file URL");
        return false;
    }

    // content:// URI 的末段通常不是真实文件名（例如 msf%3A1000000021），
    // 这里只作为导入历史的展示名，真正读取在 materialize() 中完成。
    QString name = url.fileName();
    if (name.isEmpty()) name = QStringLiteral("import.xlsx");
    source->displayName = name;
    source->key = url.toString();
    source->local = false;
    return true;
}

bool ImportFile::materialize(Source *source, QString *error, const QAtomicInt *cancel) {
    if (!source) return false;
    if (source->local) return true;

    if (source->path.isEmpty()) {
        const QString dir = cacheDir();
        if (dir.isEmpty() || !QDir().mkpath(dir)) {
            if (error) *error = QStringLiteral("Cannot create cache directory: %1").arg(dir);
            return false;
        }
        const QString fileName = QUuid::createUuid().toString(QUuid::WithoutBraces)
                                 + QStringLiteral(".xlsx");
        source->path = dir + QLatin1Char('/') + fileName;
    }

    // Android 的内容引擎支持用 QFile 读取 content URI，但 QFile::copy()
    // 不支持 content scheme，所以这里手动分块复制，顺便响应取消。
    QFile src(source->key);
    if (!src.open(QIODevice::ReadOnly)) {
        if (error) *error = QStringLiteral("Cannot open file: %1").arg(src.errorString());
        return false;
    }

    QFile dst(source->path);
    if (!dst.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (error) *error = QStringLiteral("Cannot write cache file: %1").arg(dst.errorString());
        return false;
    }

    bool ok = true;
    while (!src.atEnd()) {
        if (isCanceled(cancel)) {
            if (error) *error = QStringLiteral("Import cancelled");
            ok = false;
            break;
        }
        const QByteArray chunk = src.read(1 << 20);
        if (chunk.isEmpty()) {
            if (src.error() != QFileDevice::NoError) {
                if (error) *error = src.errorString();
                ok = false;
            }
            break;
        }
        if (dst.write(chunk) != chunk.size()) {
            if (error) *error = QStringLiteral("Cannot write cache file: %1").arg(dst.errorString());
            ok = false;
            break;
        }
    }

    dst.close();
    src.close();

    if (!ok) {
        QFile::remove(source->path);
        source->path.clear();
        return false;
    }

    const QFileInfo fi(source->path);
    if (!fi.exists() || fi.size() == 0) {
        if (error) *error = QStringLiteral("Empty file");
        QFile::remove(source->path);
        source->path.clear();
        return false;
    }

    source->size = fi.size();
    source->modified = fi.lastModified();
    source->temporary = true;
    return true;
}

void ImportFile::discard(const Source &source) {
    if (source.temporary && !source.path.isEmpty())
        QFile::remove(source.path);
}
