#include "notecontroller.h"

#include "notelistmodel.h"
#include "noterepository.h"

#include <QDebug>
#include <QPointer>
#include <QTimer>

NoteController::NoteController(NoteRepository *repository, QObject *parent)
    : QObject(parent)
    , m_repository(repository)
    , m_notesModel(new NoteListModel(this))
{
}

bool NoteController::isSaving() const
{
    return m_saving;
}

bool NoteController::isDeleting() const
{
    return m_deleting;
}

QString NoteController::errorMessage() const
{
    return m_errorMessage;
}

int NoteController::noteCount() const
{
    return m_noteCount;
}

QAbstractItemModel *NoteController::notesModel() const
{
    return m_notesModel;
}

void NoteController::saveNote(const QString &title, const QString &body)
{
    if (m_saving || m_deleting) {
        qInfo().noquote() << QStringLiteral("Save request ignored: a save is already in progress");
        return;
    }

    QString validationMessage;
    if (!isValidInput(title, body, &validationMessage)) {
        emit validationFailed(validationMessage);
        return;
    }

    setErrorMessage(QString());
    setSaving(true);

    QTimer::singleShot(0, this, [this, weakSelf = QPointer<NoteController>(this), title, body]() {
        if (!weakSelf)
            return;
        doSave(title, body);
    });
}

void NoteController::updateNote(int id, const QString &title, const QString &body)
{
    if (m_saving || m_deleting) {
        qInfo().noquote() << QStringLiteral("Update request ignored: a save is already in progress");
        return;
    }

    QString validationMessage;
    if (!isValidInput(title, body, &validationMessage)) {
        emit validationFailed(validationMessage);
        return;
    }

    if (id <= 0) {
        emit updateFailed(QStringLiteral("Invalid note"));
        return;
    }

    setErrorMessage(QString());
    setSaving(true);

    QTimer::singleShot(0, this, [this, weakSelf = QPointer<NoteController>(this), id, title, body]() {
        if (!weakSelf)
            return;
        doUpdate(id, title, body);
    });
}

void NoteController::deleteNote(int id)
{
    if (m_saving || m_deleting) {
        qInfo().noquote() << QStringLiteral("Delete request ignored: another database operation is in progress");
        return;
    }

    if (id <= 0) {
        emit deleteFailed(QStringLiteral("Invalid note"));
        return;
    }

    setErrorMessage(QString());
    m_deleting = true;
    emit deletingChanged();

    QTimer::singleShot(0, this, [this, weakSelf = QPointer<NoteController>(this), id]() {
        if (!weakSelf)
            return;
        doDelete(id);
    });
}

QVariantMap NoteController::getNote(int id) const
{
    QVariantMap result;
    if (!m_repository || id <= 0)
        return result;

    Note note;
    if (!m_repository->findNote(id, &note))
        return result;

    result.insert(QStringLiteral("id"), note.id);
    result.insert(QStringLiteral("title"), note.title);
    result.insert(QStringLiteral("body"), note.body);
    result.insert(QStringLiteral("createdAt"), note.createdAt);
    result.insert(QStringLiteral("updatedAt"), note.updatedAt);
    return result;
}

void NoteController::refreshNotes()
{
    const QList<Note> notes = m_repository ? m_repository->listNotes() : QList<Note>();
    m_notesModel->setNotes(notes);
    setNoteCount(notes.size());
    emit notesChanged();
}

void NoteController::refreshNoteCount()
{
    setNoteCount(m_repository ? m_repository->count() : 0);
}

bool NoteController::isValidInput(const QString &title, const QString &body, QString *validationMessage) const
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

void NoteController::doSave(const QString &title, const QString &body)
{
    Note createdNote;
    const bool ok = m_repository && m_repository->createNote(title, body, &createdNote);

    setSaving(false);

    if (ok) {
        refreshNotes();
        emit noteSaved();
    } else {
        const QString message = m_repository ? m_repository->lastError()
                                             : QStringLiteral("Failed to save note: database unavailable");
        setErrorMessage(message);
        emit saveFailed(message);
    }
}

void NoteController::doUpdate(int id, const QString &title, const QString &body)
{
    Note updatedNote;
    const bool ok = m_repository && m_repository->updateNote(id, title, body, &updatedNote);

    setSaving(false);

    if (ok) {
        refreshNotes();
        emit noteUpdated();
    } else {
        const QString message = m_repository ? m_repository->lastError()
                                             : QStringLiteral("Failed to update note: database unavailable");
        setErrorMessage(message);
        emit updateFailed(message);
    }
}

void NoteController::doDelete(int id)
{
    const bool ok = m_repository && m_repository->deleteNote(id);

    m_deleting = false;
    emit deletingChanged();

    if (ok) {
        refreshNotes();
        emit noteDeleted(id);
        return;
    }

    const QString message = m_repository ? m_repository->lastError()
                                         : QStringLiteral("Failed to delete note: database unavailable");
    setErrorMessage(message);
    emit deleteFailed(message);
}

void NoteController::setSaving(bool saving)
{
    if (m_saving == saving)
        return;
    m_saving = saving;
    emit savingChanged();
}

void NoteController::setErrorMessage(const QString &message)
{
    if (m_errorMessage == message)
        return;
    m_errorMessage = message;
    emit errorMessageChanged();
}

void NoteController::setNoteCount(int count)
{
    if (m_noteCount == count)
        return;
    m_noteCount = count;
    emit noteCountChanged();
}
