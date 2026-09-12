import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Window {
    id: window
    visible: true
    width: 420
    height: 760
    minimumWidth: 320
    minimumHeight: 480
    title: "MiniNotes"
    color: "#F5F5F5"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: NotesListPage {}
    }

    // --- Dev/test automation -------------------------------------------------
    readonly property bool __automation: typeof automationMode !== "undefined" && automationMode
    property var __automationPage: null
    property int __automationFailures: 0
    property int __automationInitialCount: 0

    function automationFail(message) {
        window.__automationFailures++
        console.log("AUTOMATION: **FAIL** " + message)
        automationFinished(true)
    }

    function findChildObj(item, name) {
        if (!item)
            return null
        if (item.objectName === name)
            return item
        for (var i = 0; i < item.children.length; ++i) {
            var r = findChildObj(item.children[i], name)
            if (r)
                return r
        }
        return null
    }

    Timer {
        id: automationTimer
        interval: 80
        repeat: true
        property int ticks: 0
        onTriggered: window.automationTick()
    }

    Component.onCompleted: {
        console.log("AUTOMATION-DEBUG context automationMode=" + automationMode
                    + " type=" + (typeof automationMode) + " gate=" + window.__automation)
        if (window.__automation)
            automationTimer.start()
    }

    function automationTick() {
        automationTimer.ticks++
        switch (automationTimer.ticks) {
        case 1: {
            console.log("AUTOMATION: begin")
            window.__automationInitialCount = noteController.noteCount
            var page = stackView.push("CreateNotePage.qml")
            window.__automationPage = page
            break
        }
        case 2: {
            // Empty submit must show both validation messages and must not persist.
            var p = window.__automationPage
            p.submit()
            var titleE = findChildObj(p, "titleError")
            var bodyE = findChildObj(p, "bodyError")
            if (titleE && bodyE && titleE.visible && bodyE.visible)
                console.log("AUTOMATION: validation-labels OK")
            else
                automationFail("validation-labels missing/invisible")
            if (noteController.noteCount !== window.__automationInitialCount)
                automationFail("count grew after empty submit (now " + noteController.noteCount + ")")
            break
        }
        case 3: {
            var page = window.__automationPage
            var titleF = findChildObj(page, "titleField")
            var bodyF = findChildObj(page, "bodyField")
            titleF.text = "Test Note"
            bodyF.text = "Hello Ubuntu Touch\nالعربية 😀 ' \" \\ ;"
            page.submit()
            break
        }
        case 4: {
            if (noteController.noteCount === window.__automationInitialCount + 1) {
                console.log("AUTOMATION: saved OK count=" + noteController.noteCount)
                break
            }
            if (noteController.noteCount > window.__automationInitialCount + 1) {
                automationFail("count=" + noteController.noteCount)
                return
            }
            // still waiting for the async save
            automationTimer.ticks--
            break
        }
        case 5: {
            if (stackView.depth === 1)
                console.log("AUTOMATION: auto-pop-after-save OK")
            else
                automationFail("depth=" + stackView.depth)
            automationFinished(false)
            break
        }
        default:
            if (automationTimer.ticks > 40)
                automationFail("timeout, tick=" + automationTimer.ticks)
        }
    }

    function automationFinished(failed) {
        automationTimer.stop()
        console.log(failed ? "AUTOMATION: RESULT FAIL" : "AUTOMATION: RESULT PASS")
        Qt.quit()
    }
}