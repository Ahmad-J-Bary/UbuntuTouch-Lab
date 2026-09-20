#pragma once

#include "note.h"

#include <QList>
#include <QString>

class INoteRepository
{
public:
    virtual ~INoteRepository() = default;

    virtual bool createNote(
        const QString &title,
        const QString &body,
        Note *createdNote = nullptr) = 0;

    virtual bool updateNote(
        int id,
        const QString &title,
        const QString &body,
        Note *updatedNote = nullptr) = 0;

    virtual bool deleteNote(int id) = 0;

    virtual bool findNote(int id, Note *note) const = 0;

    virtual QList<Note> listNotes() const = 0;

    virtual int count() const = 0;

    virtual QString lastError() const = 0;
};
