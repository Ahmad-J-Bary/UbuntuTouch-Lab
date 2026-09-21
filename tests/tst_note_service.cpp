#include "application/note_service.h"

#include <QtTest>

class FakeNoteRepository : public INoteRepository
{
public:
    bool failCreate = false;
    bool failUpdate = false;
    bool failDelete = false;

    QString repositoryError = QStringLiteral("Fake repository error");

    Note storedNote;
    QString error;

    bool createNote(
        const QString &title,
        const QString &body,
        Note *createdNote = nullptr) override
    {
        if (failCreate) {
            error = repositoryError;
            return false;
        }

        storedNote.id = 1;
        storedNote.title = title;
        storedNote.body = body;
        storedNote.createdAt = QStringLiteral("created");
        storedNote.updatedAt = QStringLiteral("created");

        error.clear();

        if (createdNote)
            *createdNote = storedNote;

        return true;
    }

    bool updateNote(
        int id,
        const QString &title,
        const QString &body,
        Note *updatedNote = nullptr) override
    {
        if (failUpdate) {
            error = repositoryError;
            return false;
        }

        if (id != storedNote.id) {
            error = QStringLiteral("Note was not found");
            return false;
        }

        storedNote.title = title;
        storedNote.body = body;
        storedNote.updatedAt = QStringLiteral("updated");

        error.clear();

        if (updatedNote)
            *updatedNote = storedNote;

        return true;
    }

    bool deleteNote(int id) override
    {
        if (failDelete) {
            error = repositoryError;
            return false;
        }

        if (id != storedNote.id) {
            error = QStringLiteral("Note was not found");
            return false;
        }

        storedNote = {};
        error.clear();

        return true;
    }

    bool findNote(int id, Note *note) const override
    {
        if (id <= 0 || id != storedNote.id)
            return false;

        if (note)
            *note = storedNote;

        return true;
    }

    QList<Note> listNotes() const override
    {
        if (storedNote.id <= 0)
            return {};

        return {storedNote};
    }

    int count() const override
    {
        return storedNote.id > 0 ? 1 : 0;
    }

    QString lastError() const override
    {
        return error;
    }
};

class NoteServiceTest : public QObject
{
    Q_OBJECT

private slots:
    void createTrimsInput();
    void rejectsEmptyTitle();
    void rejectsEmptyBody();
    void rejectsInvalidId();
    void propagatesRepositoryError();
    void updateAndDelete();
};

void NoteServiceTest::createTrimsInput()
{
    FakeNoteRepository repository;
    NoteService service(&repository);

    const NoteServiceResult result =
        service.createNote(
            QStringLiteral("  My Title  "),
            QStringLiteral("  My Body  "));

    QVERIFY(result.success);
    QVERIFY(!result.validationError);

    QCOMPARE(repository.storedNote.title,
             QStringLiteral("My Title"));

    QCOMPARE(repository.storedNote.body,
             QStringLiteral("My Body"));
}

void NoteServiceTest::rejectsEmptyTitle()
{
    FakeNoteRepository repository;
    NoteService service(&repository);

    const NoteServiceResult result =
        service.createNote(
            QStringLiteral("   "),
            QStringLiteral("Body"));

    QVERIFY(!result.success);
    QVERIFY(result.validationError);

    QCOMPARE(result.message,
             QStringLiteral("Title is required"));

    QCOMPARE(repository.count(), 0);
}

void NoteServiceTest::rejectsEmptyBody()
{
    FakeNoteRepository repository;
    NoteService service(&repository);

    const NoteServiceResult result =
        service.createNote(
            QStringLiteral("Title"),
            QStringLiteral(" \n\t "));

    QVERIFY(!result.success);
    QVERIFY(result.validationError);

    QCOMPARE(result.message,
             QStringLiteral("Content is required"));

    QCOMPARE(repository.count(), 0);
}

void NoteServiceTest::rejectsInvalidId()
{
    FakeNoteRepository repository;
    NoteService service(&repository);

    QString validationMessage;

    QVERIFY(!service.validateNoteId(
        0,
        &validationMessage));

    QCOMPARE(
        validationMessage,
        QStringLiteral("Invalid note"));
}

void NoteServiceTest::propagatesRepositoryError()
{
    FakeNoteRepository repository;
    repository.failCreate = true;

    NoteService service(&repository);

    const NoteServiceResult result =
        service.createNote(
            QStringLiteral("Title"),
            QStringLiteral("Body"));

    QVERIFY(!result.success);
    QVERIFY(!result.validationError);

    QCOMPARE(
        result.message,
        QStringLiteral("Fake repository error"));
}

void NoteServiceTest::updateAndDelete()
{
    FakeNoteRepository repository;
    NoteService service(&repository);

    const NoteServiceResult createResult =
        service.createNote(
            QStringLiteral("Title"),
            QStringLiteral("Body"));

    QVERIFY(createResult.success);
    QCOMPARE(repository.count(), 1);

    const NoteServiceResult updateResult =
        service.updateNote(
            createResult.note.id,
            QStringLiteral("Updated"),
            QStringLiteral("New body"));

    QVERIFY(updateResult.success);

    QCOMPARE(
        repository.storedNote.title,
        QStringLiteral("Updated"));

    QCOMPARE(
        repository.storedNote.body,
        QStringLiteral("New body"));

    const NoteServiceResult deleteResult =
        service.deleteNote(createResult.note.id);

    QVERIFY(deleteResult.success);
    QCOMPARE(repository.count(), 0);
}

QTEST_GUILESS_MAIN(NoteServiceTest)

#include "tst_note_service.moc"
