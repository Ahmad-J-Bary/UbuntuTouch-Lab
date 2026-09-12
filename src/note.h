#pragma once

#include <QString>

struct Note
{
    int id = -1;
    QString title;
    QString body;
    QString createdAt;
    QString updatedAt;
};