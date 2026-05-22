import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property string searchText: ""
  property int selectedIndex: 0

  ListModel { id: apps }
  ListModel { id: filtered }

  function rebuild() {
    filtered.clear()
    const q = searchText.toLowerCase()
    for (let i = 0; i < apps.count; i++) {
      const app = apps.get(i)
      if (q === "" || app.name.toLowerCase().includes(q) || app.comment.toLowerCase().includes(q)) filtered.append(app)
    }
    if (selectedIndex >= filtered.count) selectedIndex = Math.max(0, filtered.count - 1)
  }

  Process {
    id: loader
    running: true
    command: [Quickshell.shellDir + "/scripts/list-apps.sh"]
    stdout: SplitParser {
      onRead: line => {
        const parts = line.split("|")
        if (parts.length >= 4) apps.append({ name: parts[0], comment: parts[1], icon: parts[2], command: parts[3], terminal: parts.length >= 5 && parts[4].toLowerCase() === "true" })
      }
    }
    onRunningChanged: if (!running) rebuild()
  }

  Process { id: launchProc; running: false; onExited: Qt.quit() }
  function move(delta) { if (filtered.count > 0) selectedIndex = (selectedIndex + delta + filtered.count) % filtered.count }
  function launchSelected() {
    if (filtered.count === 0) return
    const app = filtered.get(selectedIndex)
    const cmd = app.terminal ? "ghostty -e " + app.command : app.command
    launchProc.command = ["bash", "-lc", "setsid -f " + cmd + " >/dev/null 2>&1"]
    launchProc.running = true
  }
  onSearchTextChanged: { selectedIndex = 0; rebuild() }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.68)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-launcher"

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Qt.quit() }
    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) { root.move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) { root.move(1); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.launchSelected(); event.accepted = true }
        else if (event.key === Qt.Key_Backspace) { root.searchText = root.searchText.slice(0, -1); event.accepted = true }
        else if (event.key === Qt.Key_U && event.modifiers & Qt.ControlModifier) { root.searchText = ""; event.accepted = true }
        else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.MetaModifier)) { root.searchText += event.text; event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.width - 120, 920)
      height: Math.min(parent.height - 120, 620)
      radius: 22
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          radius: 14
          color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.86)
          border.width: 1
          border.color: theme.borderGlow
          Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: root.searchText.length ? root.searchText : "search applications"; color: root.searchText.length ? theme.fgPrimary : theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeNormal }
          Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: `${filtered.count}/${apps.count}`; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeSmall }
        }
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: filtered
            currentIndex: root.selectedIndex
            spacing: 6
            delegate: Rectangle {
            id: row
            required property int index
            required property string name
            required property string comment
            required property string icon
            width: ListView.view.width
            height: 74
            radius: 14
            color: index === root.selectedIndex ? theme.hoverBg : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            border.width: index === root.selectedIndex ? 1 : 0
            border.color: theme.borderGlow
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 12
              Image { Layout.preferredWidth: 40; Layout.preferredHeight: 40; source: icon ? Quickshell.iconPath(icon, true) : ""; smooth: true; asynchronous: true; fillMode: Image.PreserveAspectFit }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: row.name; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeNormal; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: row.comment; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeSmall; elide: Text.ElideRight; Layout.fillWidth: true }
              }
            }
              MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = row.index; onClicked: root.launchSelected() }
            }
          }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            visible: filtered.count === 0
            Text { Layout.alignment: Qt.AlignHCenter; text: "󰱼"; color: theme.accentPink; font.family: theme.symbols; font.pixelSize: 42 }
            Text { Layout.alignment: Qt.AlignHCenter; text: apps.count === 0 ? "No applications found" : "No matches"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: "type to search · enter to launch · esc to close"; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          }
        }
      }
    }
  }
}
