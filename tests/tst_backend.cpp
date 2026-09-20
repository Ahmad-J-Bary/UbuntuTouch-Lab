#include "database.h"
#include "notecontroller.h"
#include "noterepository.h"

#include <QSignalSpy>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QtTest>

class BackendTest : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testValidNote();
    void testEmptyTitle();
    void testEmptyBody();
    void testLongTextUtf8();
    void testSpecialCharacters();
    void testDuplicateSaveRequest();
    void testDatabaseFailure();
    void testPersistenceAcrossReopen();
    void testListNotes();
    void testFindNote();
    void testUpdateNote();
    void testDeleteNote();

private:
    int count() const;
    bool fetchLatestNote(int *id, QString *title, QString *body, QString *createdAt, QString *updatedAt) const;

    QTemporaryDir m_dir;
    Database *m_database = nullptr;
    NoteRepository *m_repository = nullptr;
    NoteController *m_controller = nullptr;
};

void BackendTest::initTestCase()
{
    QVERIFY(m_dir.isValid());
    const QString dbPath = m_dir.path() + QStringLiteral("/mininotes_test.db");

    m_database = new Database();
    QString error;
    QVERIFY2(m_database->open(dbPath, &error), qPrintable(error));
    QVERIFY2(m_database->createSchema(&error), qPrintable(error));

    m_repository = new NoteRepository(m_database);
    m_controller = new NoteController(m_repository);
}

int BackendTest::count() const
{
    return m_repository->count();
}

bool BackendTest::fetchLatestNote(int *id, QString *title, QString *body, QString *createdAt, QString *updatedAt) const
{
    QSqlQuery query(m_database->connection());
    if (!query.exec(QStringLiteral("SELECT id, title, body, created_at, updated_at "
                                   "FROM notes ORDER BY id DESC LIMIT 1")))
        return false;
    if (!query.next())
        return false;
    if (id) *id = query.value(0).toInt();
    if (title) *title = query.value(1).toString();
    if (body) *body = query.value(2).toString();
    if (createdAt) *createdAt = query.value(3).toString();
    if (updatedAt) *updatedAt = query.value(4).toString();
    return true;
}

void BackendTest::testValidNote()
{
    const int before = count();
    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(QStringLiteral("Test Note"), QStringLiteral("Hello Ubuntu Touch"));
    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QCOMPARE(savedSpy.count(), 1);
    QCOMPARE(count(), before + 1);
}

void BackendTest::testEmptyTitle()
{
    const int before = count();
    QSignalSpy validationSpy(m_controller, &NoteController::validationFailed);
    m_controller->saveNote(QStringLiteral("   "), QStringLiteral("Some body"));
    QCOMPARE(validationSpy.count(), 1);
    QCOMPARE(validationSpy.takeFirst().at(0).toString(), QStringLiteral("Title is required"));
    QCOMPARE(count(), before);
}

void BackendTest::testEmptyBody()
{
    const int before = count();
    QSignalSpy validationSpy(m_controller, &NoteController::validationFailed);
    m_controller->saveNote(QStringLiteral("Title"), QStringLiteral(" \n "));
    QCOMPARE(validationSpy.count(), 1);
    QCOMPARE(validationSpy.takeFirst().at(0).toString(), QStringLiteral("Content is required"));
    QCOMPARE(count(), before);
}

void BackendTest::testLongTextUtf8()
{
    QString englishPart;
    for (int i = 0; i < 100; ++i)
        englishPart += QStringLiteral("The quick brown fox jumps over the lazy dog. ");

    const QString title = QStringLiteral("العنوان الطويل: ") + englishPart.mid(0, 500) + QStringLiteral(" — نهاية العنوان");
    const QString body = QStringLiteral("بداية النص بالعربية.\n") + englishPart
        + QStringLiteral("\nنص عربي ممزوج باللاتيني Hello World 123.\n😀");

    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(title, body);
    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QVERIFY(savedSpy.count() == 1);

    QString storedTitle, storedBody;
    QVERIFY(fetchLatestNote(nullptr, &storedTitle, &storedBody, nullptr, nullptr));
    QCOMPARE(storedTitle, title);
    QCOMPARE(storedBody, body.trimmed());
}

void BackendTest::testSpecialCharacters()
{
    const QString title = QStringLiteral("Special: ' \" \\ ; 😀");
    const QString body = QStringLiteral("Line1 ' \" \\ ;\nالعربية\n😀");
    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(title, body);
    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QString storedTitle, storedBody;
    QVERIFY(fetchLatestNote(nullptr, &storedTitle, &storedBody, nullptr, nullptr));
    QCOMPARE(storedTitle, title);
    QCOMPARE(storedBody, body);
}

void BackendTest::testDuplicateSaveRequest()
{
    const int before = count();
    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(QStringLiteral("First note"), QStringLiteral("First body"));
    m_controller->saveNote(QStringLiteral("Second note"), QStringLiteral("Second body"));
    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QCOMPARE(savedSpy.count(), 1);
    QCOMPARE(count(), before + 1);
}

void BackendTest::testDatabaseFailure()
{
    Database brokenDatabase;
    NoteRepository repository(&brokenDatabase);
    NoteController controller(&repository);
    QSignalSpy failedSpy(&controller, &NoteController::saveFailed);
    controller.saveNote(QStringLiteral("Title"), QStringLiteral("Body"));
    QVERIFY2(failedSpy.wait(3000), "saveFailed signal was not emitted");
    QCOMPARE(failedSpy.count(), 1);
}

void BackendTest::testPersistenceAcrossReopen()
{
    const QString dbPath = m_dir.path() + QStringLiteral("/persistence_test.db");
    {
        Database db1;
        QString error;
        QVERIFY2(db1.open(dbPath, &error), qPrintable(error));
        QVERIFY2(db1.createSchema(&error), qPrintable(error));
        NoteRepository repo(&db1);
        NoteController controller(&repo);
        QSignalSpy savedSpy(&controller, &NoteController::noteSaved);
        controller.saveNote(QStringLiteral("Persistent Note"), QStringLiteral("Still here after restart"));
        QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
        QCOMPARE(controller.noteCount(), 1);
    }
    {
        Database db2;
        QString error;
        QVERIFY2(db2.open(dbPath, &error), qPrintable(error));
        QVERIFY2(db2.createSchema(&error), qPrintable(error));
        QSqlQuery query(db2.connection());
        QVERIFY(query.exec(QStringLiteral("SELECT title, body FROM notes ORDER BY id DESC LIMIT 1")));
        QVERIFY(query.next());
        QCOMPARE(query.value(0).toString(), QStringLiteral("Persistent Note"));
        QCOMPARE(query.value(1).toString(), QStringLiteral("Still here after restart"));
    }
}

void BackendTest::testListNotes()
{
    const QList<Note> notes = m_repository->listNotes();
    QVERIFY(!notes.isEmpty());
    QVERIFY(notes.first().id > 0);
    QVERIFY(!notes.first().title.isEmpty());
}

void BackendTest::testFindNote()
{
    int id = -1;
    QString title, body;
    QVERIFY(fetchLatestNote(&id, &title, &body, nullptr, nullptr));

    Note note;
    QVERIFY(m_repository->findNote(id, &note));
    QCOMPARE(note.id, id);
    QCOMPARE(note.title, title);
    QCOMPARE(note.body, body);

    QVERIFY(!m_repository->findNote(-1, nullptr));
}

void BackendTest::testUpdateNote()
{
    int id = -1;
    QVERIFY(fetchLatestNote(&id, nullptr, nullptr, nullptr, nullptr));

    const QString oldBody = m_repository->listNotes().first().body;
    Note updated;

    QSignalSpy updatedSpy(m_controller, &NoteController::noteUpdated);
    m_controller->updateNote(id, QStringLiteral("Edited title"), QStringLiteral("Edited body 😀 العربية"));
    QVERIFY2(updatedSpy.wait(3000), "noteUpdated signal was not emitted");
    QCOMPARE(updatedSpy.count(), 1);

    QVERIFY(m_repository->findNote(id, &updated));
    QCOMPARE(updated.title, QStringLiteral("Edited title"));
    QCOMPARE(updated.body, QStringLiteral("Edited body 😀 العربية"));
    QVERIFY(updated.updatedAt >= updated.createdAt);
    Q_UNUSED(oldBody);
}

void BackendTest::testDeleteNote()
{
    const int before = count();

    int id = -1;
    QVERIFY(fetchLatestNote(&id, nullptr, nullptr, nullptr, nullptr));
    QVERIFY(id > 0);

    QSignalSpy deletedSpy(m_controller, &NoteController::noteDeleted);
    m_controller->deleteNote(id);

    QVERIFY2(deletedSpy.wait(3000), "noteDeleted signal was not emitted");
    QCOMPARE(deletedSpy.count(), 1);
    QCOMPARE(deletedSpy.takeFirst().at(0).toInt(), id);
    QCOMPARE(count(), before - 1);

    Note deleted;
    QVERIFY(!m_repository->findNote(id, &deleted));
}

QTEST_GUILESS_MAIN(BackendTest)
#include "tst_backend.moc"
