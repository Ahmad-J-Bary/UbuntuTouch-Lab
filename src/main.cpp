#include "database.h"
#include "notecontroller.h"
#include "noterepository.h"

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QStandardPaths>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QUrl>

#include <QDebug>

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
    QCoreApplication::setOrganizationName(QStringLiteral("MiniNotes"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("mininotes.local"));
    QCoreApplication::setApplicationName(QStringLiteral("mininotes"));

    QGuiApplication app(argc, argv);

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dataDir.isEmpty())
        dataDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);

    const QString databasePath = dataDir + QStringLiteral("/mininotes.db");

    Database database;
    QString dbError;
    if (!database.open(databasePath, &dbError)) {
        qWarning().noquote() << QStringLiteral("Application data database is unavailable: %1").arg(dbError);
    } else if (!database.createSchema(&dbError)) {
        qWarning().noquote() << QStringLiteral("Could not initialise application schema: %1").arg(dbError);
    }

    NoteRepository repository(&database);
    NoteController controller(&repository);
    controller.refreshNoteCount();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("noteController"), &controller);
    engine.rootContext()->setContextProperty(QStringLiteral("automationMode"),
                                             qEnvironmentVariableIsSet("MININOTES_E2E_TEST"));
    engine.load(QUrl::fromLocalFile(resolveQmlMain()));

    if (engine.rootObjects().isEmpty()) {
        qCritical().noquote() << QStringLiteral("Failed to load the QML user interface");
        return EXIT_FAILURE;
    }

    if (qEnvironmentVariableIsSet("MININOTES_SMOKE_TEST"))
        QTimer::singleShot(2500, &app, &QCoreApplication::quit);

    return app.exec();
}