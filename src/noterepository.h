#pragma once

#include "note.h"

#include <QList>
#include <QString>

class Database;

class NoteRepository
{
public:
    explicit NoteRepository(Database *database);

    NoteRepository(const NoteRepository &) = delete;
    NoteRepository &operator=(const NoteRepository &) = delete;

    bool createNote(const QString &title, const QString &body, Note *createdNote = nullptr);
    bool updateNote(int id, const QString &title, const QString &body, Note *updatedNote = nullptr);
    bool deleteNote(int id);
    bool findNote(int id, Note *note) const;
    QList<Note> listNotes() const;
    int count() const;
    QString lastError() const;

private:
    Database *m_database;
    mutable QString m_lastError;
};
