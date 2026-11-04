#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDebug>
#include <QThreadPool>

#include "model/accountmanager.h"
#include "model/billmodel.h"
#include "model/languagemanager.h"
#include "thememanager.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("autoPurseManager");
    app.setOrganizationName("RL");
    app.setWindowIcon(QIcon(":/icon.svg"));
    app.setApplicationVersion("1.0.0");

    AccountManager accountManager;
    accountManager.init();

    BillModel model;
    LanguageManager langManager;
    ThemeManager themeManager;

    QQmlApplicationEngine engine;
    engine.addImportPath(":/");
    engine.rootContext()->setContextProperty("billModel", &model);
    engine.rootContext()->setContextProperty("accountManager", &accountManager);
    engine.rootContext()->setContextProperty("langManager", &langManager);
    engine.rootContext()->setContextProperty("themeManager", &themeManager);

    engine.loadFromModule("AutoPurse", "Main");
    if (engine.rootObjects().isEmpty()) {
        qWarning() << "Failed to load QML";
        return -1;
    }

    return app.exec();
    int ret = app.exec();
    QThreadPool::globalInstance()->waitForDone(5000);
    return ret;
}