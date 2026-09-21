#pragma once

#include <QSqlDatabase>
#include <QString>

class Database
{
public:
    explicit Database(const QString &connectionName = QString());
    ~Database();

    Database(const Database &) = delete;
    Database &operator=(const Database &) = delete;

    bool open(const QString &path, QString *errorMessage = nullptr);
    bool createSchema(QString *errorMessage = nullptr);
    void close();

    bool isOpen() const;
    QString path() const;
    QSqlDatabase connection() const;

private:
    QString m_connectionName;
    QString m_path;
};
