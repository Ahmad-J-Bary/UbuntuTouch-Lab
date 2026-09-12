#include "noterepository.h"

#include "database.h"

#include <QDateTime>
#include <QDebug>
#include <QObject>
#include <QSqlError>
#include <QSqlQuery>

NoteRepository::NoteRepository(Database *database)
    : m_database(database)
{
}

bool NoteRepository::createNote(const QString &title, const QString &body, Note *createdNote)
{
    m_lastError.clear();

    const QString trimmedTitle = title.trimmed();
    const QString trimmedBody = body.trimmed();

    if (trimmedTitle.isEmpty()) {
        m_lastError = QObject::tr("Title is required");
        return false;
    }
    if (trimmedBody.isEmpty()) {
        m_lastError = QObject::tr("Content is required");
        return false;
    }

    if (!m_database || !m_database->isOpen()) {
        m_lastError = QObject::tr("Database is not open");
        qCritical().noquote() << m_lastError;
        return false;
    }

    QSqlQuery query(m_database->connection());
    query.prepare(QStringLiteral(
        "INSERT INTO notes (title, body, created_at, updated_at) "
        "VALUES (?, ?, ?, ?)"));

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    query.addBindValue(trimmedTitle);
    query.addBindValue(trimmedBody);
    query.addBindValue(timestamp);
    query.addBindValue(timestamp);

    if (!query.exec()) {
        m_lastError = QObject::tr("Failed to save note: %1").arg(query.lastError().text());
        qCritical().noquote() << m_lastError;
        return false;
    }

    if (createdNote) {
        Note note;
        note.id = query.lastInsertId().toInt();
        note.title = trimmedTitle;
        note.body = trimmedBody;
        note.createdAt = timestamp;
        note.updatedAt = timestamp;
        *createdNote = note;
    }

    return true;
}

int NoteRepository::count() const
{
    QSqlQuery query(m_database ? m_database->connection() : QSqlDatabase());
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM notes")) || !query.next()) {
        qWarning().noquote() << QStringLiteral("Failed to count notes: %1").arg(query.lastError().text());
        return 0;
    }
    return query.value(0).toInt();
}

QString NoteRepository::lastError() const
{
    return m_lastError;
}