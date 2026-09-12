#pragma once

#include <QObject>
#include <QString>

class NoteRepository;

class NoteController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool saving READ isSaving NOTIFY savingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY noteCountChanged)

public:
    explicit NoteController(NoteRepository *repository, QObject *parent = nullptr);

    bool isSaving() const;
    QString errorMessage() const;
    int noteCount() const;

    Q_INVOKABLE void saveNote(const QString &title, const QString &body);
    Q_INVOKABLE void refreshNoteCount();

signals:
    void noteSaved();
    void validationFailed(const QString &message);
    void saveFailed(const QString &message);
    void savingChanged();
    void errorMessageChanged();
    void noteCountChanged();

private:
    void setSaving(bool saving);
    void setErrorMessage(const QString &message);
    bool isValidInput(const QString &title, const QString &body, QString *validationMessage) const;
    void doSave(const QString &title, const QString &body);
    void setNoteCount(int count);

    NoteRepository *m_repository;
    bool m_saving = false;
    QString m_errorMessage;
    int m_noteCount = 0;
};