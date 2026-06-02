import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property string query: ""
  property int selectedIndex: 0
  property var entries: []
  readonly property var filteredEntries: entries.filter(item => item.toLowerCase().includes(query.toLowerCase()))

  Process {
    id: loadProc
    running: true
    command: ["bash", "-lc", "cliphist list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.entries = this.text.split("\n").filter(line => line.length > 0)
        root.selectedIndex = 0
      }
    }
  }

  Process { id: copyProc; running: false; onExited: Qt.quit() }
  Process { id: clearProc; running: false; onExited: Qt.quit() }

  function clampSelection() {
    if (filteredEntries.length === 0) selectedIndex = 0
    else selectedIndex = Math.max(0, Math.min(selectedIndex, filteredEntries.length - 1))
  }

  function move(delta) {
    if (filteredEntries.length === 0) return
    selectedIndex = (selectedIndex + delta + filteredEntries.length) % filteredEntries.length
  }

  function copySelected() {
    if (filteredEntries.length === 0) return
    copyProc.command = ["bash", "-lc", "printf '%s' \"$1\" | cliphist decode | wl-copy", "clipboard", filteredEntries[selectedIndex]]
    copyProc.running = true
  }

  function clearHistory() {
    clearProc.command = ["bash", "-lc", "cliphist wipe && notify-send 'Clipboard history cleared'"]
    clearProc.running = true
  }

  onQueryChanged: {
    selectedIndex = 0
    clampSelection()
  }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.68)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-clipboard"

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.RightButton
      onClicked: Qt.quit()
      onWheel: event => {
        root.move(event.angleDelta.y > 0 ? -1 : 1)
        event.accepted = true
      }
    }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) { root.move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) { root.move(1); event.accepted = true }
        else if (event.key === Qt.Key_PageUp) { root.move(-6); event.accepted = true }
        else if (event.key === Qt.Key_PageDown) { root.move(6); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.copySelected(); event.accepted = true }
        else if (event.key === Qt.Key_Backspace) { root.query = root.query.slice(0, -1); event.accepted = true }
        else if (event.key === Qt.Key_U && event.modifiers & Qt.ControlModifier) { root.query = ""; event.accepted = true }
        else if (event.key === Qt.Key_W && event.modifiers & Qt.ControlModifier) { root.query = root.query.replace(/\s*\S+\s*$/, ""); event.accepted = true }
        else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.MetaModifier)) { root.query += event.text; event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.width - 120, 860)
      height: Math.min(parent.height - 140, 600)
      radius: 22
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow
      antialiasing: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: "Clipboard"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeLarge; font.bold: true }
            Text { text: "type to filter · enter to copy · right-click or esc to close"; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeSmall }
          }

          Rectangle {
            Layout.preferredWidth: 118
            Layout.preferredHeight: 44
            radius: 10
            color: clearMouse.containsMouse ? Qt.rgba(theme.accentRed.r, theme.accentRed.g, theme.accentRed.b, 0.24) : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.72)
            border.width: 1
            border.color: clearMouse.containsMouse ? theme.accentRed : theme.borderGlow
            Text { anchors.centerIn: parent; text: "Clear"; color: clearMouse.containsMouse ? theme.accentRed : theme.fgSecondary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeNormal }
            MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearHistory() }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 56
          radius: 12
          color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.86)
          border.width: 1
          border.color: theme.borderGlow

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            Text { text: "󰈙"; color: theme.accentPink; font.family: theme.symbols; font.pixelSize: theme.fontSizeIcon }
            Text { Layout.fillWidth: true; text: root.query.length > 0 ? root.query : "search clipboard history"; color: root.query.length > 0 ? theme.fgPrimary : theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeNormal; elide: Text.ElideRight }
            Text { text: `${root.filteredEntries.length}/${root.entries.length}`; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeSmall }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: root.filteredEntries
            currentIndex: root.selectedIndex
            spacing: 6

            delegate: Rectangle {
            id: row
            required property int index
            required property string modelData
            width: ListView.view.width
            height: 68
            radius: 12
            color: index === root.selectedIndex ? theme.hoverBg : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            border.width: index === root.selectedIndex ? 1 : 0
            border.color: theme.borderGlow

            Text {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              anchors.verticalCenter: parent.verticalCenter
              verticalAlignment: Text.AlignVCenter
              text: row.modelData
              color: index === root.selectedIndex ? theme.fgPrimary : theme.fgSecondary
              font.family: theme.uiFont
              font.pixelSize: theme.fontSizeNormal
              elide: Text.ElideRight
            }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = row.index
                onClicked: root.copySelected()
              }
            }
          }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            visible: root.filteredEntries.length === 0
            Text { Layout.alignment: Qt.AlignHCenter; text: "󰅇"; color: theme.accentPink; font.family: theme.symbols; font.pixelSize: 42 }
            Text { Layout.alignment: Qt.AlignHCenter; text: root.entries.length === 0 ? "Clipboard history is empty" : "No clipboard matches"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: "copy something or adjust your filter"; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          }
        }
      }
    }
  }
}
