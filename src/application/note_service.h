#pragma once

#include "domain/inote_repository.h"

#include <QList>
#include <QString>

struct NoteServiceResult
{
    bool success = false;
    bool validationError = false;
    QString message;
    Note note;
};

class NoteService
{
public:
    explicit NoteService(INoteRepository *repository);

    bool validateNoteInput(
        const QString &title,
        const QString &body,
        QString *validationMessage = nullptr) const;

    bool validateNoteId(
        int id,
        QString *validationMessage = nullptr) const;

    NoteServiceResult createNote(
        const QString &title,
        const QString &body);

    NoteServiceResult updateNote(
        int id,
        const QString &title,
        const QString &body);

    NoteServiceResult deleteNote(int id);

    bool findNote(
        int id,
        Note *note,
        QString *errorMessage = nullptr) const;

    QList<Note> listNotes() const;

    int count() const;

private:
    INoteRepository *m_repository;
};
