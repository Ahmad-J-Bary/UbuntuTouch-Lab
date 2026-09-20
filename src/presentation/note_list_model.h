#pragma once

#include "note.h"

#include <QAbstractListModel>
#include <QList>

class NoteListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        NoteIdRole = Qt::UserRole + 1,
        TitleRole,
        BodyRole,
        CreatedAtRole,
        UpdatedAtRole
    };

    explicit NoteListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setNotes(const QList<Note> &notes);

private:
    QList<Note> m_notes;
};
