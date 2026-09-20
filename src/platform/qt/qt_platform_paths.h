#pragma once

#include "platform/platform_paths.h"

class QtPlatformPaths final : public IPlatformPaths
{
public:
    QString applicationDataDirectory() const override;

    QString databasePath() const override;

    bool ensureApplicationDataDirectory(
        QString *errorMessage = nullptr) const override;
};
