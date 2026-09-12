#pragma once

#include "note.h"
#include <QString>

class Database;

class NoteRepository
{
public:
    explicit NoteRepository(Database *database);

    NoteRepository(const NoteRepository &) = delete;
    NoteRepository &operator=(const NoteRepository &) = delete;

    bool createNote(const QString &title, const QString &body, Note *createdNote = nullptr);
    int count() const;
    QString lastError() const;

private:
    Database *m_database;
    mutable QString m_lastError;
};