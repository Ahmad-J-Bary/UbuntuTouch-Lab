#pragma once

#include <QAbstractItemModel>
#include <QObject>
#include <QString>
#include <QVariantMap>

class INoteRepository;
class NoteListModel;

class NoteController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool saving READ isSaving NOTIFY savingChanged)
    Q_PROPERTY(bool deleting READ isDeleting NOTIFY deletingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY noteCountChanged)
    Q_PROPERTY(QAbstractItemModel *notesModel READ notesModel CONSTANT)

public:
    explicit NoteController(INoteRepository *repository, QObject *parent = nullptr);

    bool isSaving() const;
    bool isDeleting() const;
    QString errorMessage() const;
    int noteCount() const;
    QAbstractItemModel *notesModel() const;

    Q_INVOKABLE void saveNote(const QString &title, const QString &body);
    Q_INVOKABLE void updateNote(int id, const QString &title, const QString &body);
    Q_INVOKABLE QVariantMap getNote(int id) const;
    Q_INVOKABLE void refreshNotes();
    Q_INVOKABLE void refreshNoteCount();
    Q_INVOKABLE void deleteNote(int id);

signals:
    void noteSaved();
    void noteUpdated();
    void noteDeleted(int id);
    void validationFailed(const QString &message);
    void saveFailed(const QString &message);
    void updateFailed(const QString &message);
    void deleteFailed(const QString &message);
    void savingChanged();
    void deletingChanged();
    void errorMessageChanged();
    void noteCountChanged();
    void notesChanged();

private:
    void setSaving(bool saving);
    void setErrorMessage(const QString &message);
    bool isValidInput(const QString &title, const QString &body, QString *validationMessage) const;
    void doSave(const QString &title, const QString &body);
    void doUpdate(int id, const QString &title, const QString &body);
    void doDelete(int id);
    void setNoteCount(int count);

    INoteRepository *m_repository;
    NoteListModel *m_notesModel;
    bool m_saving = false;
    bool m_deleting = false;
    QString m_errorMessage;
    int m_noteCount = 0;
};
