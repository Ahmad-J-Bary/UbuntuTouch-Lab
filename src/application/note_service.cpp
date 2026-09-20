#include "note_service.h"

NoteService::NoteService(INoteRepository *repository)
    : m_repository(repository)
{
}

bool NoteService::validateNoteInput(
    const QString &title,
    const QString &body,
    QString *validationMessage) const
{
    if (title.trimmed().isEmpty()) {
        if (validationMessage)
            *validationMessage = QStringLiteral("Title is required");
        return false;
    }

    if (body.trimmed().isEmpty()) {
        if (validationMessage)
            *validationMessage = QStringLiteral("Content is required");
        return false;
    }

    return true;
}

bool NoteService::validateNoteId(
    int id,
    QString *validationMessage) const
{
    if (id <= 0) {
        if (validationMessage)
            *validationMessage = QStringLiteral("Invalid note");
        return false;
    }

    return true;
}

NoteServiceResult NoteService::createNote(
    const QString &title,
    const QString &body)
{
    QString validationMessage;

    if (!validateNoteInput(title, body, &validationMessage)) {
        return {
            false,
            true,
            validationMessage,
            {}
        };
    }

    if (!m_repository) {
        return {
            false,
            false,
            QStringLiteral("Repository unavailable"),
            {}
        };
    }

    Note createdNote;

    const QString normalizedTitle = title.trimmed();
    const QString normalizedBody = body.trimmed();

    if (!m_repository->createNote(
            normalizedTitle,
            normalizedBody,
            &createdNote)) {
        const QString repositoryError = m_repository->lastError();

        return {
            false,
            false,
            repositoryError.isEmpty()
                ? QStringLiteral("Failed to save note")
                : repositoryError,
            {}
        };
    }

    return {
        true,
        false,
        QString(),
        createdNote
    };
}

NoteServiceResult NoteService::updateNote(
    int id,
    const QString &title,
    const QString &body)
{
    QString validationMessage;

    if (!validateNoteId(id, &validationMessage)) {
        return {
            false,
            true,
            validationMessage,
            {}
        };
    }

    if (!validateNoteInput(title, body, &validationMessage)) {
        return {
            false,
            true,
            validationMessage,
            {}
        };
    }

    if (!m_repository) {
        return {
            false,
            false,
            QStringLiteral("Repository unavailable"),
            {}
        };
    }

    Note updatedNote;

    const QString normalizedTitle = title.trimmed();
    const QString normalizedBody = body.trimmed();

    if (!m_repository->updateNote(
            id,
            normalizedTitle,
            normalizedBody,
            &updatedNote)) {
        const QString repositoryError = m_repository->lastError();

        return {
            false,
            false,
            repositoryError.isEmpty()
                ? QStringLiteral("Failed to update note")
                : repositoryError,
            {}
        };
    }

    return {
        true,
        false,
        QString(),
        updatedNote
    };
}

NoteServiceResult NoteService::deleteNote(int id)
{
    QString validationMessage;

    if (!validateNoteId(id, &validationMessage)) {
        return {
            false,
            true,
            validationMessage,
            {}
        };
    }

    if (!m_repository) {
        return {
            false,
            false,
            QStringLiteral("Repository unavailable"),
            {}
        };
    }

    if (!m_repository->deleteNote(id)) {
        const QString repositoryError = m_repository->lastError();

        return {
            false,
            false,
            repositoryError.isEmpty()
                ? QStringLiteral("Failed to delete note")
                : repositoryError,
            {}
        };
    }

    return {
        true,
        false,
        QString(),
        {}
    };
}

bool NoteService::findNote(
    int id,
    Note *note,
    QString *errorMessage) const
{
    QString validationMessage;

    if (!validateNoteId(id, &validationMessage)) {
        if (errorMessage)
            *errorMessage = validationMessage;
        return false;
    }

    if (!m_repository) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Repository unavailable");
        return false;
    }

    if (!m_repository->findNote(id, note)) {
        if (errorMessage)
            *errorMessage = m_repository->lastError();
        return false;
    }

    return true;
}

QList<Note> NoteService::listNotes() const
{
    if (!m_repository)
        return {};

    return m_repository->listNotes();
}

int NoteService::count() const
{
    if (!m_repository)
        return 0;

    return m_repository->count();
}
