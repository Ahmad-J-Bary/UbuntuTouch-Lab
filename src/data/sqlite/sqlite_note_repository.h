#pragma once

#include "domain/inote_repository.h"

#include <QList>
#include <QString>

class Database;

class SqliteNoteRepository : public INoteRepository
{
public:
    explicit SqliteNoteRepository(Database *database);

    SqliteNoteRepository(const SqliteNoteRepository &) = delete;
    SqliteNoteRepository &operator=(const SqliteNoteRepository &) = delete;

    bool createNote(
        const QString &title,
        const QString &body,
        Note *createdNote = nullptr) override;

    bool updateNote(
        int id,
        const QString &title,
        const QString &body,
        Note *updatedNote = nullptr) override;

    bool deleteNote(int id) override;

    bool findNote(int id, Note *note) const override;

    QList<Note> listNotes() const override;

    int count() const override;

    QString lastError() const override;

private:
    Database *m_database;
    mutable QString m_lastError;
};