import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property int selectedIndex: 0
  readonly property var actions: [
    { "name": "LOCK", "icon": "󰌾", "hint": "hyprlock", "cmd": "hyprlock", "danger": false },
    { "name": "LOGOUT", "icon": "󰍃", "hint": "exit Hyprland", "cmd": "hyprctl dispatch exit", "danger": false },
    { "name": "SUSPEND", "icon": "󰒲", "hint": "systemctl suspend", "cmd": "systemctl suspend", "danger": false },
    { "name": "REBOOT", "icon": "󰜉", "hint": "systemctl reboot", "cmd": "systemctl reboot", "danger": true },
    { "name": "SHUTDOWN", "icon": "󰐥", "hint": "systemctl poweroff", "cmd": "systemctl poweroff", "danger": true }
  ]

  Process { id: runner; running: false; onExited: Qt.quit() }
  function move(delta) { selectedIndex = (selectedIndex + delta + actions.length) % actions.length }
  function runSelected() { runner.command = ["bash", "-lc", actions[selectedIndex].cmd]; runner.running = true }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.72)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-power"

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Qt.quit(); onWheel: event => { root.move(event.angleDelta.y > 0 ? -1 : 1); event.accepted = true } }
    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Up || event.key === Qt.Key_K) { root.move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) { root.move(1); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.runSelected(); event.accepted = true }
        else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) { root.selectedIndex = event.key - Qt.Key_1; root.runSelected(); event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 780
      height: 220
      radius: 18
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow

      RowLayout {
        anchors.centerIn: parent
        spacing: 16
        Repeater {
          model: root.actions.length
          delegate: Rectangle {
            id: tile
            required property int index
            readonly property var action: root.actions[index]
            readonly property bool selected: root.selectedIndex === index
            Layout.preferredWidth: 136
            Layout.preferredHeight: 154
            radius: 16
            color: selected ? Qt.rgba((action.danger ? theme.accentRed : theme.accentBlue).r, (action.danger ? theme.accentRed : theme.accentBlue).g, (action.danger ? theme.accentRed : theme.accentBlue).b, 0.28) : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
            border.width: selected ? 1 : 0
            border.color: action.danger ? theme.accentRed : theme.accentBlue
            Behavior on color { ColorAnimation { duration: 160 } }

            Column {
              anchors.centerIn: parent
              spacing: 8
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: tile.action.icon; color: tile.action.danger ? theme.accentRed : theme.fgPrimary; font.family: theme.symbols; font.pixelSize: 36 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: tile.action.name; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeNormal; font.bold: tile.selected }
              Text { anchors.horizontalCenter: parent.horizontalCenter; width: 122; horizontalAlignment: Text.AlignHCenter; text: tile.action.hint; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: theme.fontSizeSmall; wrapMode: Text.WordWrap }
            }

            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = tile.index; onClicked: root.runSelected() }
          }
        }
      }
    }
  }
}
