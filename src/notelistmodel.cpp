#include "notelistmodel.h"

NoteListModel::NoteListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int NoteListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_notes.size();
}

QVariant NoteListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_notes.size())
        return {};

    const Note &note = m_notes.at(index.row());

    switch (role) {
    case NoteIdRole:
        return note.id;
    case TitleRole:
        return note.title;
    case BodyRole:
        return note.body;
    case CreatedAtRole:
        return note.createdAt;
    case UpdatedAtRole:
        return note.updatedAt;
    default:
        return {};
    }
}

QHash<int, QByteArray> NoteListModel::roleNames() const
{
    return {
        { NoteIdRole, "noteId" },
        { TitleRole, "title" },
        { BodyRole, "body" },
        { CreatedAtRole, "createdAt" },
        { UpdatedAtRole, "updatedAt" }
    };
}

void NoteListModel::setNotes(const QList<Note> &notes)
{
    beginResetModel();
    m_notes = notes;
    endResetModel();
}
