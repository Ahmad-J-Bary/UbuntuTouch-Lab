#include "qt_platform_paths.h"

#include <QDir>
#include <QStandardPaths>

QString QtPlatformPaths::applicationDataDirectory() const
{
    QString dataDir =
        QStandardPaths::writableLocation(
            QStandardPaths::AppDataLocation);

    if (dataDir.isEmpty()) {
        dataDir =
            QStandardPaths::writableLocation(
                QStandardPaths::HomeLocation);
    }

    return QDir::cleanPath(dataDir);
}

QString QtPlatformPaths::databasePath() const
{
    const QString dataDir =
        applicationDataDirectory();

    if (dataDir.isEmpty())
        return {};

    return QDir(dataDir).filePath(
        QStringLiteral("mininotes.db"));
}

bool QtPlatformPaths::ensureApplicationDataDirectory(
    QString *errorMessage) const
{
    const QString dataDir =
        applicationDataDirectory();

    if (dataDir.isEmpty()) {
        if (errorMessage) {
            *errorMessage =
                QStringLiteral(
                    "Application data directory is unavailable");
        }

        return false;
    }

    QDir directory;

    if (directory.exists(dataDir))
        return true;

    if (directory.mkpath(dataDir))
        return true;

    if (errorMessage) {
        *errorMessage =
            QStringLiteral(
                "Could not create application data directory: %1")
                .arg(dataDir);
    }

    return false;
}
