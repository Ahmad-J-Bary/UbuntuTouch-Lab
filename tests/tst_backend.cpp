#include "database.h"
#include "notecontroller.h"
#include "noterepository.h"

#include <QSignalSpy>
#include <QSqlError>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QtTest>

static const QString kTitle = QStringLiteral("Test Note");
static const QString kBody = QStringLiteral("Hello Ubuntu Touch");

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
    if (id)
        *id = query.value(0).toInt();
    if (title)
        *title = query.value(1).toString();
    if (body)
        *body = query.value(2).toString();
    if (createdAt)
        *createdAt = query.value(3).toString();
    if (updatedAt)
        *updatedAt = query.value(4).toString();
    return true;
}

void BackendTest::testValidNote()
{
    const int before = count();

    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(kTitle, kBody);

    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QCOMPARE(savedSpy.count(), 1);
    QCOMPARE(count(), before + 1);

    int id = -1;
    QString title, body, createdAt, updatedAt;
    QVERIFY(fetchLatestNote(&id, &title, &body, &createdAt, &updatedAt));
    QCOMPARE(title, kTitle);
    QCOMPARE(body, kBody);
    QVERIFY(!createdAt.isEmpty());
    QCOMPARE(createdAt, updatedAt);
    QVERIFY(id > before);
}

void BackendTest::testEmptyTitle()
{
    const int before = count();

    QSignalSpy validationSpy(m_controller, &NoteController::validationFailed);
    m_controller->saveNote(QStringLiteral("   "), QStringLiteral("Some body"));

    QCOMPARE(validationSpy.count(), 1);
    QCOMPARE(validationSpy.takeFirst().at(0).toString(), QStringLiteral("Title is required"));
    QCOMPARE(count(), before);

    Note note;
    QVERIFY(!m_repository->createNote(QString(), QStringLiteral("body"), &note));
}

void BackendTest::testEmptyBody()
{
    const int before = count();

    QSignalSpy validationSpy(m_controller, &NoteController::validationFailed);
    m_controller->saveNote(QStringLiteral("Title"), QStringLiteral(" \n "));

    QCOMPARE(validationSpy.count(), 1);
    QCOMPARE(validationSpy.takeFirst().at(0).toString(), QStringLiteral("Content is required"));
    QCOMPARE(count(), before);

    Note note;
    QVERIFY(!m_repository->createNote(QStringLiteral("Title"), QString(), &note));
}

void BackendTest::testLongTextUtf8()
{
    const int before = count();

    QString englishPart;
    for (int i = 0; i < 200; ++i)
        englishPart += QStringLiteral("The quick brown fox jumps over the lazy dog. ");

    const QString title = QStringLiteral("العنوان الطويل: ") + englishPart.mid(0, 500) + QStringLiteral(" — نهاية العنوان");
    const QString body = QStringLiteral("بداية النص بالعربية.\n")
        + englishPart
        + QStringLiteral("\nنص عربي ممزوج باللاتيني Hello World 123.\n")
        + QStringLiteral("سطر أخير.");

    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(title, body);

    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QCOMPARE(savedSpy.count(), 1);
    QCOMPARE(count(), before + 1);

    QString storedTitle, storedBody;
    QVERIFY(fetchLatestNote(nullptr, &storedTitle, &storedBody, nullptr, nullptr));
    QCOMPARE(storedTitle, title);
    QCOMPARE(storedBody, body);
}

void BackendTest::testSpecialCharacters()
{
    const int before = count();

    const QString title = QStringLiteral("Special: ' \" \\ ; -- % _ , 😀");
    const QString body = QStringLiteral("Line1 with ' single quotes \" double quotes \\ backslash ; semicolon\n"
        "رموز عربية: العربية\n"
        "\ufeff BOM test \t tab\n")
        + QString::fromUtf8("emoji 😀 mixed العربية English \" \' \\ ;");

    QSignalSpy savedSpy(m_controller, &NoteController::noteSaved);
    m_controller->saveNote(title, body);

    QVERIFY2(savedSpy.wait(3000), "noteSaved signal was not emitted");
    QCOMPARE(savedSpy.count(), 1);
    QCOMPARE(count(), before + 1);

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

    QString title;
    QVERIFY(fetchLatestNote(nullptr, &title, nullptr, nullptr, nullptr));
    QCOMPARE(title, QStringLiteral("First note"));
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
    QVERIFY(!controller.errorMessage().isEmpty());
}

void BackendTest::testPersistenceAcrossReopen()
{
    const QString dbPath = m_dir.path() + QStringLiteral("/persistence_test.db");
    const QString title = QStringLiteral("Persistent Note");
    const QString body = QStringLiteral("Still here after restart");

    {
        Database db1;
        QString error;
        QVERIFY2(db1.open(dbPath, &error), qPrintable(error));
        QVERIFY2(db1.createSchema(&error), qPrintable(error));

        NoteRepository repo(&db1);
        NoteController controller(&repo);
        controller.refreshNoteCount();
        QCOMPARE(controller.noteCount(), 0);

        QSignalSpy savedSpy(&controller, &NoteController::noteSaved);
        controller.saveNote(title, body);
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
        QCOMPARE(query.value(0).toString(), title);
        QCOMPARE(query.value(1).toString(), body);

        NoteRepository repo(&db2);
        QCOMPARE(repo.count(), 1);
    }
}

QTEST_GUILESS_MAIN(BackendTest)

#include "tst_backend.moc"