#include "data/sqlite/database.h"
#include "data/sqlite/sqlite_note_repository.h"
#include "platform/qt/qt_platform_paths.h"
#include "application/note_service.h"
#include "presentation/note_controller.h"

#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QUrl>

static QString resolveQmlMain()
{
    const QString appDir = QCoreApplication::applicationDirPath();

    const QStringList candidates = {
        appDir + QStringLiteral("/qml/Main.qml"),
        appDir + QStringLiteral("/../qml/Main.qml"),
    };

    for (const QString &candidate : candidates) {
        if (QFile::exists(candidate))
            return candidate;
    }

    return candidates.first();
}

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationDomain(QStringLiteral("mininotes.local"));
    QCoreApplication::setApplicationName(QStringLiteral("mininotes"));

    QGuiApplication app(argc, argv);

    QtPlatformPaths platformPaths;

    QString pathError;

    if (!platformPaths.ensureApplicationDataDirectory(&pathError)) {
        qWarning().noquote()
            << QStringLiteral("Application data directory is unavailable: %1")
                   .arg(pathError);
    }

    const QString dataDir =
        platformPaths.applicationDataDirectory();

    const QString databasePath =
        platformPaths.databasePath();

    qInfo().noquote()
        << QStringLiteral("MiniNotes startup: appDir=%1 qml=%2 dataDir=%3 database=%4")
               .arg(QCoreApplication::applicationDirPath(),
                    resolveQmlMain(),
                    dataDir,
                    databasePath);

    Database database;
    QString dbError;

    if (!database.open(databasePath, &dbError)) {
        qWarning().noquote()
            << QStringLiteral("Application data database is unavailable: %1")
                   .arg(dbError);
    } else if (!database.createSchema(&dbError)) {
        qWarning().noquote()
            << QStringLiteral("Could not initialise application schema: %1")
                   .arg(dbError);
    }

    SqliteNoteRepository repository(&database);
    NoteService service(&repository);
    NoteController controller(&service);
    controller.refreshNotes();

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [](QObject *object, const QUrl &url) {
            if (!object) {
                qCritical().noquote()
                    << QStringLiteral("QML object creation failed: %1")
                           .arg(url.toString());
            }
        },
        Qt::QueuedConnection);

    engine.rootContext()->setContextProperty(
        QStringLiteral("noteController"),
        &controller);

    engine.rootContext()->setContextProperty(
        QStringLiteral("automationMode"),
        qEnvironmentVariableIsSet("MININOTES_E2E_TEST"));

    const QUrl qmlMain = QUrl::fromLocalFile(resolveQmlMain());
    qInfo().noquote()
        << QStringLiteral("Loading QML: %1").arg(qmlMain.toString());

    engine.load(qmlMain);

    if (engine.rootObjects().isEmpty()) {
        qCritical().noquote()
            << QStringLiteral("Failed to load the QML user interface");
        return EXIT_FAILURE;
    }

    qInfo() << "MiniNotes QML root loaded successfully";

    if (qEnvironmentVariableIsSet("MININOTES_SMOKE_TEST")) {
        QTimer::singleShot(
            2500,
            &app,
            &QCoreApplication::quit);
    }

    return app.exec();
}
