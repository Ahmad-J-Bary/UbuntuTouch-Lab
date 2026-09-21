#include "note_controller.h"

#include "application/note_service.h"
#include "note_list_model.h"

#include <QPointer>
#include <QTimer>
#include <QDebug>

NoteController::NoteController(
    NoteService *service,
    QObject *parent)
    : QObject(parent)
    , m_service(service)
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

void NoteController::saveNote(
    const QString &title,
    const QString &body)
{
    if (m_saving || m_deleting) {
        qInfo().noquote()
            << QStringLiteral(
                   "Save request ignored: a database operation is already in progress");
        return;
    }

    if (!m_service) {
        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit saveFailed(message);
        return;
    }

    QString validationMessage;

    if (!m_service->validateNoteInput(
            title,
            body,
            &validationMessage)) {

        emit validationFailed(validationMessage);
        return;
    }

    setErrorMessage(QString());
    setSaving(true);

    QTimer::singleShot(
        0,
        this,
        [this,
         weakSelf = QPointer<NoteController>(this),
         title,
         body]() {
            if (!weakSelf)
                return;

            doSave(title, body);
        });
}

void NoteController::updateNote(
    int id,
    const QString &title,
    const QString &body)
{
    if (m_saving || m_deleting) {
        qInfo().noquote()
            << QStringLiteral(
                   "Update request ignored: a database operation is already in progress");
        return;
    }

    if (!m_service) {
        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit updateFailed(message);
        return;
    }

    QString validationMessage;

    if (!m_service->validateNoteId(
            id,
            &validationMessage)) {

        emit updateFailed(validationMessage);
        return;
    }

    if (!m_service->validateNoteInput(
            title,
            body,
            &validationMessage)) {

        emit validationFailed(validationMessage);
        return;
    }

    setErrorMessage(QString());
    setSaving(true);

    QTimer::singleShot(
        0,
        this,
        [this,
         weakSelf = QPointer<NoteController>(this),
         id,
         title,
         body]() {
            if (!weakSelf)
                return;

            doUpdate(id, title, body);
        });
}

void NoteController::deleteNote(int id)
{
    if (m_saving || m_deleting) {
        qInfo().noquote()
            << QStringLiteral(
                   "Delete request ignored: another database operation is in progress");
        return;
    }

    if (!m_service) {
        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit deleteFailed(message);
        return;
    }

    QString validationMessage;

    if (!m_service->validateNoteId(
            id,
            &validationMessage)) {

        emit deleteFailed(validationMessage);
        return;
    }

    setErrorMessage(QString());

    m_deleting = true;
    emit deletingChanged();

    QTimer::singleShot(
        0,
        this,
        [this,
         weakSelf = QPointer<NoteController>(this),
         id]() {
            if (!weakSelf)
                return;

            doDelete(id);
        });
}

QVariantMap NoteController::getNote(int id) const
{
    QVariantMap result;

    if (!m_service)
        return result;

    Note note;

    if (!m_service->findNote(id, &note))
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
    const QList<Note> notes =
        m_service
            ? m_service->listNotes()
            : QList<Note>();

    m_notesModel->setNotes(notes);
    setNoteCount(notes.size());

    emit notesChanged();
}

void NoteController::refreshNoteCount()
{
    setNoteCount(
        m_service
            ? m_service->count()
            : 0);
}

void NoteController::doSave(
    const QString &title,
    const QString &body)
{
    if (!m_service) {
        setSaving(false);

        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit saveFailed(message);
        return;
    }

    const NoteServiceResult result =
        m_service->createNote(title, body);

    setSaving(false);

    if (result.success) {
        refreshNotes();
        emit noteSaved();
        return;
    }

    if (result.validationError) {
        emit validationFailed(result.message);
        return;
    }

    setErrorMessage(result.message);
    emit saveFailed(result.message);
}

void NoteController::doUpdate(
    int id,
    const QString &title,
    const QString &body)
{
    if (!m_service) {
        setSaving(false);

        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit updateFailed(message);
        return;
    }

    const NoteServiceResult result =
        m_service->updateNote(id, title, body);

    setSaving(false);

    if (result.success) {
        refreshNotes();
        emit noteUpdated();
        return;
    }

    if (result.validationError) {
        emit validationFailed(result.message);
        return;
    }

    setErrorMessage(result.message);
    emit updateFailed(result.message);
}

void NoteController::doDelete(int id)
{
    if (!m_service) {
        m_deleting = false;
        emit deletingChanged();

        const QString message =
            QStringLiteral("Application service unavailable");

        setErrorMessage(message);
        emit deleteFailed(message);
        return;
    }

    const NoteServiceResult result =
        m_service->deleteNote(id);

    m_deleting = false;
    emit deletingChanged();

    if (result.success) {
        refreshNotes();
        emit noteDeleted(id);
        return;
    }

    setErrorMessage(result.message);
    emit deleteFailed(result.message);
}

void NoteController::setSaving(bool saving)
{
    if (m_saving == saving)
        return;

    m_saving = saving;
    emit savingChanged();
}

void NoteController::setErrorMessage(
    const QString &message)
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
