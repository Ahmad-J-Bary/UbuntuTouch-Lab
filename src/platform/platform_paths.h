#pragma once

#include <QString>

class IPlatformPaths
{
public:
    virtual ~IPlatformPaths() = default;

    virtual QString applicationDataDirectory() const = 0;

    virtual QString databasePath() const = 0;

    virtual bool ensureApplicationDataDirectory(
        QString *errorMessage = nullptr) const = 0;
};
