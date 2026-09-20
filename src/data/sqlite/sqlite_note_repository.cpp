#include "sqlite_note_repository.h"

#include "database.h"

#include <QDateTime>
#include <QDebug>
#include <QObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

SqliteNoteRepository::SqliteNoteRepository(Database *database)
    : m_database(database)
{
}

bool SqliteNoteRepository::createNote(const QString &title, const QString &body, Note *createdNote)
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

bool SqliteNoteRepository::updateNote(int id, const QString &title, const QString &body, Note *updatedNote)
{
    m_lastError.clear();

    const QString trimmedTitle = title.trimmed();
    const QString trimmedBody = body.trimmed();

    if (id <= 0) {
        m_lastError = QObject::tr("Invalid note");
        return false;
    }
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

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery query(m_database->connection());
    query.prepare(QStringLiteral(
        "UPDATE notes SET title = ?, body = ?, updated_at = ? WHERE id = ?"));
    query.addBindValue(trimmedTitle);
    query.addBindValue(trimmedBody);
    query.addBindValue(timestamp);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QObject::tr("Failed to update note: %1").arg(query.lastError().text());
        qCritical().noquote() << m_lastError;
        return false;
    }

    if (query.numRowsAffected() != 1) {
        m_lastError = QObject::tr("Note was not found");
        return false;
    }

    if (updatedNote) {
        Note note;
        if (!findNote(id, &note)) {
            m_lastError = QObject::tr("Note was updated but could not be reloaded");
            return false;
        }
        *updatedNote = note;
    }

    return true;
}

bool SqliteNoteRepository::deleteNote(int id)
{
    m_lastError.clear();

    if (id <= 0) {
        m_lastError = QObject::tr("Invalid note");
        return false;
    }

    if (!m_database || !m_database->isOpen()) {
        m_lastError = QObject::tr("Database is not open");
        qCritical().noquote() << m_lastError;
        return false;
    }

    QSqlQuery query(m_database->connection());
    query.prepare(QStringLiteral("DELETE FROM notes WHERE id = ?"));
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QObject::tr("Failed to delete note: %1").arg(query.lastError().text());
        qCritical().noquote() << m_lastError;
        return false;
    }

    if (query.numRowsAffected() != 1) {
        m_lastError = QObject::tr("Note was not found");
        return false;
    }

    return true;
}

bool SqliteNoteRepository::findNote(int id, Note *note) const
{
    m_lastError.clear();

    if (id <= 0 || !m_database || !m_database->isOpen())
        return false;

    QSqlQuery query(m_database->connection());
    query.prepare(QStringLiteral(
        "SELECT id, title, body, created_at, updated_at "
        "FROM notes WHERE id = ? LIMIT 1"));
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QObject::tr("Failed to read note: %1").arg(query.lastError().text());
        qWarning().noquote() << m_lastError;
        return false;
    }

    if (!query.next())
        return false;

    if (note) {
        note->id = query.value(0).toInt();
        note->title = query.value(1).toString();
        note->body = query.value(2).toString();
        note->createdAt = query.value(3).toString();
        note->updatedAt = query.value(4).toString();
    }

    return true;
}

QList<Note> SqliteNoteRepository::listNotes() const
{
    m_lastError.clear();

    QList<Note> notes;
    if (!m_database || !m_database->isOpen())
        return notes;

    QSqlQuery query(m_database->connection());
    if (!query.exec(QStringLiteral(
            "SELECT id, title, body, created_at, updated_at "
            "FROM notes ORDER BY updated_at DESC, id DESC"))) {
        m_lastError = QObject::tr("Failed to list notes: %1").arg(query.lastError().text());
        qWarning().noquote() << m_lastError;
        return notes;
    }

    while (query.next()) {
        Note note;
        note.id = query.value(0).toInt();
        note.title = query.value(1).toString();
        note.body = query.value(2).toString();
        note.createdAt = query.value(3).toString();
        note.updatedAt = query.value(4).toString();
        notes.append(note);
    }

    return notes;
}

int SqliteNoteRepository::count() const
{
    QSqlQuery query(m_database ? m_database->connection() : QSqlDatabase());
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM notes")) || !query.next()) {
        qWarning().noquote() << QStringLiteral("Failed to count notes: %1").arg(query.lastError().text());
        return 0;
    }
    return query.value(0).toInt();
}

QString SqliteNoteRepository::lastError() const
{
    return m_lastError;
}
