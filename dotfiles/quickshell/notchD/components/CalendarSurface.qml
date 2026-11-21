import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Flickable {
    id: root
    property var state: null
    property date selectedDate: new Date(Services.Time.now)
    property date displayedMonth: new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1, 12)
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7
    readonly property int offset: (displayedMonth.getDay() - firstWeekday + 7) % 7
    readonly property int weekCount: Math.ceil((offset + new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 0).getDate()) / 7)
    readonly property int selectedIndex: selectedDate.getFullYear() === displayedMonth.getFullYear() && selectedDate.getMonth() === displayedMonth.getMonth() ? selectedDate.getDate() + offset - 1 : -1
    contentWidth: width
    contentHeight: content.implicitHeight
    implicitHeight: content.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    function cellDate(index) {
        return new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), index - offset + 1, 12);
    }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
    function select(date, focus) {
        selectedDate = new Date(date);
        displayedMonth = new Date(date.getFullYear(), date.getMonth(), 1, 12);
        if (focus)
            Qt.callLater(focusSelection);
    }
    function moveDays(amount) {
        select(new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + amount, 12), true);
    }
    function moveMonth(amount) {
        const target = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + amount, 1, 12);
        const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0, 12).getDate();
        select(new Date(target.getFullYear(), target.getMonth(), Math.min(selectedDate.getDate(), lastDay), 12), true);
    }
    function focusSelection() {
        const item = days.itemAt(selectedIndex);
        if (item) {
            item.forceActiveFocus();
            const position = item.mapToItem(content, 0, 0);
            if (position.y < contentY)
                contentY = Math.max(0, position.y);
            else if (position.y + item.height > contentY + height)
                contentY = Math.min(Math.max(0, contentHeight - height), position.y + item.height - height);
        }
    }
    onActiveFocusChanged: if (activeFocus)
        Qt.callLater(focusSelection)
    ColumnLayout {
        id: content
        width: root.width
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 36
            }
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 20 * Theme.textScale
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            NavButton {
                label: "Today"
                accessibleLabel: "Go to today"
                onClicked: root.select(Services.Time.now, true)
            }
            NavButton {
                label: "‹"
                accessibleLabel: "Previous month"
                onClicked: root.moveMonth(-1)
            }
            NavButton {
                label: "›"
                accessibleLabel: "Next month"
                onClicked: root.moveMonth(1)
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 8
            rowSpacing: 6
            Repeater {
                model: 7
                delegate: Text {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.formatDate(new Date(2024, 0, 7 + (root.firstWeekday + index) % 7), "ddd")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                }
            }
            Repeater {
                id: days
                model: root.weekCount * 7
                delegate: Rectangle {
                    required property int index
                    readonly property date date: root.cellDate(index)
                    readonly property bool currentMonth: date.getMonth() === root.displayedMonth.getMonth()
                    readonly property bool selected: root.sameDay(date, root.selectedDate)
                    readonly property bool today: root.sameDay(date, Services.Time.now)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: 34
                    radius: 10
                    color: selected ? Theme.accent : dayMouse.pressed ? Theme.surfacePress : dayMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: activeFocus ? Theme.fg : today ? Theme.accent : "transparent"
                    activeFocusOnTab: currentMonth
                    Accessible.role: Accessible.Button
                    Accessible.name: Qt.formatDate(date, "dddd, d MMMM yyyy") + (today ? ", today" : "")
                    Accessible.description: selected ? "Selected date" : ""
                    Accessible.onPressAction: root.select(date, true)
                    Text {
                        anchors.centerIn: parent
                        text: parent.date.getDate()
                        color: parent.selected ? Theme.accentInk : parent.currentMonth ? Theme.fg : Theme.muted
                        opacity: parent.currentMonth || parent.selected ? 1 : 0.55
                        font.family: Theme.fontFamily
                        font.pixelSize: 12 * Theme.textScale
                        font.weight: parent.today || parent.selected ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(parent.date, true)
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left)
                            root.moveDays(-1);
                        else if (event.key === Qt.Key_Right)
                            root.moveDays(1);
                        else if (event.key === Qt.Key_Up)
                            root.moveDays(-7);
                        else if (event.key === Qt.Key_Down)
                            root.moveDays(7);
                        else if (event.key === Qt.Key_PageUp)
                            root.moveMonth(-1);
                        else if (event.key === Qt.Key_PageDown)
                            root.moveMonth(1);
                        else if (event.key === Qt.Key_Home)
                            root.select(Services.Time.now, true);
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space)
                            root.select(date, true);
                        else
                            return;
                        event.accepted = true;
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(root.selectedDate, "dddd, d MMMM yyyy")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12 * Theme.textScale
                elide: Text.ElideRight
            }
            Text {
                text: Services.Time.zone
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
            }
        }
    }
    component NavButton: Rectangle {
        id: button
        property string label: ""
        property string accessibleLabel: label
        signal clicked
        implicitWidth: Math.max(32, navText.implicitWidth + 20)
        implicitHeight: 32
        radius: 10
        color: navMouse.pressed ? Theme.surfacePress : navMouse.containsMouse || activeFocus ? Theme.surfaceHover : Theme.surface
        border.color: activeFocus ? Theme.accent : "transparent"
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: accessibleLabel
        Accessible.onPressAction: clicked()
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
        Text {
            id: navText
            anchors.centerIn: parent
            text: button.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12 * Theme.textScale
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
