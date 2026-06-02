import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
  id: root
  required property QtObject theme
  spacing: 4

  function workspaceFor(id) {
    for (let i = 0; i < Hyprland.workspaces.length; i++) {
      const ws = Hyprland.workspaces[i]
      if (ws.id === id) return ws
    }
    return null
  }

  Repeater {
    model: 10

    MouseArea {
      id: button
      required property int index
      property int workspaceId: index + 1
      property var workspace: root.workspaceFor(workspaceId)
      property bool active: !!(Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
        ? Hyprland.focusedMonitor.activeWorkspace.id === workspaceId
        : workspace && (workspace.focused || workspace.active))
      property bool occupied: !!(workspace && workspace.toplevels && workspace.toplevels.length > 0)
      property bool urgent: !!(workspace && workspace.urgent)

      Layout.preferredWidth: active || occupied || workspaceId <= 4 ? 44 : 24
      Layout.preferredHeight: 36
      opacity: active || occupied || workspaceId <= 4 ? 1.0 : 0.42
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 160 } }

      Rectangle {
        anchors.centerIn: parent
        width: parent.width - 4
        height: 30
        radius: 8
        color: button.active
          ? Qt.rgba(root.theme.accentBlue.r, root.theme.accentBlue.g, root.theme.accentBlue.b, 0.30)
          : button.containsMouse
            ? Qt.rgba(1, 1, 1, 0.09)
            : "transparent"
        border.width: button.active || button.containsMouse ? 1 : 0
        border.color: button.active ? root.theme.border2 : Qt.rgba(1, 1, 1, 0.14)

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.width { NumberAnimation { duration: 140 } }
      }

      Text {
        anchors.centerIn: parent
        text: button.workspaceId.toString()
        color: button.urgent ? root.theme.accentRed
          : button.active ? root.theme.fgPrimary
          : button.occupied ? root.theme.fgSecondary
          : root.theme.fgTertiary
        font.family: root.theme.uiFont
        font.pixelSize: 20
        font.bold: button.active
      }

      onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", workspaceId.toString()])
    }
  }
}
