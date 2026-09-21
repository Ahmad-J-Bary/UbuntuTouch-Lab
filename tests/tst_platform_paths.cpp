#include "platform/qt/qt_platform_paths.h"

#include <QDir>
#include <QFileInfo>
#include <QtTest>

class PlatformPathsTest : public QObject
{
    Q_OBJECT

private slots:
    void applicationDataDirectoryIsAvailable();
    void databasePathIsInsideApplicationDataDirectory();
    void applicationDataDirectoryCanBeEnsured();
};

void PlatformPathsTest::applicationDataDirectoryIsAvailable()
{
    QtPlatformPaths paths;

    const QString dataDir =
        paths.applicationDataDirectory();

    QVERIFY(!dataDir.isEmpty());
}

void PlatformPathsTest::databasePathIsInsideApplicationDataDirectory()
{
    QtPlatformPaths paths;

    const QString dataDir =
        QDir::cleanPath(
            paths.applicationDataDirectory());

    const QString databasePath =
        QDir::cleanPath(
            paths.databasePath());

    QVERIFY(!databasePath.isEmpty());
    QCOMPARE(
        QFileInfo(databasePath).absolutePath(),
        QDir(dataDir).absolutePath());

    QVERIFY(databasePath.endsWith(
        QStringLiteral("/mininotes.db")));
}

void PlatformPathsTest::applicationDataDirectoryCanBeEnsured()
{
    QtPlatformPaths paths;

    QString error;

    QVERIFY2(
        paths.ensureApplicationDataDirectory(&error),
        qPrintable(error));

    QVERIFY(
        QDir(
            paths.applicationDataDirectory()).exists());
}

QTEST_GUILESS_MAIN(PlatformPathsTest)

#include "tst_platform_paths.moc"
