#include "database.h"

#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

Database::Database(const QString &connectionName)
    : m_connectionName(connectionName.isEmpty()
          ? QStringLiteral("mininotes_") + QUuid::createUuid().toString(QUuid::WithoutBraces)
          : connectionName)
{
}

Database::~Database()
{
    close();
}

bool Database::open(const QString &path, QString *errorMessage)
{
    const QString error = [&]() -> QString {
        QDir directory = QFileInfo(path).absoluteDir();
        if (!directory.exists() && !directory.mkpath(QStringLiteral(".")))
            return QStringLiteral("Could not create data directory: %1").arg(directory.absolutePath());

        QSqlDatabase database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
        database.setDatabaseName(path);

        if (!database.open())
            return QStringLiteral("Could not open database (%1): %2").arg(path, database.lastError().text());

        m_path = path;
        qInfo().noquote() << QStringLiteral("Database opened at %1").arg(path);
        return QString();
    }();

    if (!error.isEmpty()) {
        qCritical().noquote() << error;
        if (errorMessage)
            *errorMessage = error;
        return false;
    }
    return true;
}

bool Database::createSchema(QString *errorMessage)
{
    if (!isOpen()) {
        const QString error = QStringLiteral("Cannot create schema: database is not open");
        qCritical().noquote() << error;
        if (errorMessage)
            *errorMessage = error;
        return false;
    }

    const QString schema = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS notes ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "title TEXT NOT NULL, "
        "body TEXT NOT NULL, "
        "created_at TEXT NOT NULL, "
        "updated_at TEXT NOT NULL)");

    QSqlQuery query(connection());
    if (!query.exec(schema)) {
        const QString error = QStringLiteral("Failed to create notes table: %1").arg(query.lastError().text());
        qCritical().noquote() << error;
        if (errorMessage)
            *errorMessage = error;
        return false;
    }

    qInfo().noquote() << QStringLiteral("Notes table is ready");
    return true;
}

void Database::close()
{
    if (m_connectionName.isEmpty())
        return;

    {
        QSqlDatabase database = QSqlDatabase::database(m_connectionName, false);
        if (database.isValid() && database.isOpen())
            database.close();
    }
    QSqlDatabase::removeDatabase(m_connectionName);
    m_path.clear();
}

bool Database::isOpen() const
{
    QSqlDatabase database = QSqlDatabase::database(m_connectionName, false);
    return database.isValid() && database.isOpen();
}

QString Database::path() const
{
    return m_path;
}

QSqlDatabase Database::connection() const
{
    return QSqlDatabase::database(m_connectionName, false);
}