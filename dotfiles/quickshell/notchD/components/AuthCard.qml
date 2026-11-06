import QtQuick
import QtQuick.Layouts
import ".."

// Native polkit authentication card. Rendered by notchD itself so password
// prompts never leave the island.
Item {
    id: root

    property var flow: null

    implicitWidth: Theme.authW
    implicitHeight: Theme.authH

    Panel {
        anchors.fill: parent
        panelRadius: Theme.radius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 28
                height: 28
                radius: 9
                color: Theme.surface
                border.width: 1
                border.color: Theme.hairlineSoft
                Icon {
                    anchors.centerIn: parent
                    glyph: "\uf023"
                    size: 13
                    tint: Theme.fg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: "Authentication required"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: root.flow ? String(root.flow.actionId || "") : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Text {
            Layout.fillWidth: true
            text: root.flow ? String(root.flow.message || "") : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.flow ? String(root.flow.supplementaryMessage || "") : ""
            color: root.flow && root.flow.supplementaryIsError ? Theme.danger : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 9
            color: Theme.surface
            border.width: 1
            border.color: pwd.activeFocus ? Theme.fg : Theme.hairline

            TextInput {
                id: pwd
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
                echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                selectionColor: Theme.fg
                selectedTextColor: Theme.bg
                clip: true
                focus: visible
                onVisibleChanged: {
                    if (visible) { text = ""; forceActiveFocus(); }
                }
                onAccepted: root.submit()
                Keys.onEscapePressed: (event) => {
                    root.cancel();
                    event.accepted = true;
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: pwd.text.length === 0
                text: root.flow && root.flow.inputPrompt.length > 0
                    ? String(root.flow.inputPrompt)
                    : "Password"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 74
                height: 28
                radius: 8
                color: cancelMouse.containsMouse ? Theme.surfaceHover : "transparent"
                border.width: 1
                border.color: Theme.hairline
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancel()
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 84
                height: 28
                radius: 8
                color: Theme.fg
                Text {
                    anchors.centerIn: parent
                    text: "Authenticate"
                    color: Theme.accentInk
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submit()
                }
            }
        }
    }

    function submit() {
        if (!root.flow) return;
        root.flow.submit(pwd.text);
        pwd.text = "";
    }

    function cancel() {
        if (!root.flow) return;
        root.flow.cancelAuthenticationRequest();
    }
}
