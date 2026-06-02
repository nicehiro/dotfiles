import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property string status: "Stopped"
  property string title: "Nothing playing"
  property string artist: ""
  property string player: ""
  property string position: "--:--"
  property string length: "--:--"
  property string artUrl: ""
  property real progress: 0

  function normalizedArtUrl(value) {
    if (!value) return ""
    if (value.startsWith("file://") || value.startsWith("http://") || value.startsWith("https://")) return value
    if (value.startsWith("/")) return "file://" + value
    return value
  }

  function run(action) {
    actionProc.command = ["bash", "-lc", "playerctl " + action + " >/dev/null 2>&1 || true"]
    actionProc.running = false
    actionProc.running = true
  }

  Process { id: actionProc; running: false; onExited: refresh.running = true }

  Process {
    id: refresh
    running: true
    command: ["bash", "-lc", "playerctl metadata --format '{{status}}|{{playerName}}|{{artist}}|{{title}}|{{duration(position)}}|{{duration(mpris:length)}}|{{position}}|{{mpris:length}}|{{mpris:artUrl}}' 2>/dev/null || printf 'Stopped||||--:--|--:--|0|0|'"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("|")
        root.status = parts[0] || "Stopped"
        root.player = parts[1] || ""
        root.artist = parts[2] || ""
        root.title = parts[3] || "Nothing playing"
        root.position = parts[4] || "--:--"
        root.length = parts[5] || "--:--"
        const pos = parseFloat(parts[6]) || 0
        const len = parseFloat(parts[7]) || 0
        root.artUrl = root.normalizedArtUrl(parts.slice(8).join("|"))
        root.progress = len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
      }
    }
  }

  Timer { interval: 1500; running: true; repeat: true; onTriggered: { refresh.running = false; refresh.running = true } }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.50)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-media"

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Qt.quit() }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Space || event.key === Qt.Key_K) { root.run("play-pause"); event.accepted = true }
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) { root.run("previous"); event.accepted = true }
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) { root.run("next"); event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 780
      height: 360
      radius: 22
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow
      antialiasing: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        RowLayout {
          Layout.fillWidth: true
          spacing: 14

          Rectangle {
            Layout.preferredWidth: 132
            Layout.preferredHeight: 132
            radius: 20
            color: Qt.rgba(theme.accentPurple.r, theme.accentPurple.g, theme.accentPurple.b, 0.22)
            border.width: 1
            border.color: theme.borderGlow
            clip: true

            Image {
              anchors.fill: parent
              source: root.artUrl
              visible: root.artUrl.length > 0
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              smooth: true
            }

            Rectangle {
              anchors.fill: parent
              visible: root.artUrl.length > 0
              color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.12)
            }

            Text { anchors.centerIn: parent; visible: root.artUrl.length === 0; text: root.status === "Playing" ? "󰎆" : "󰝛"; color: theme.accentPink; font.family: theme.symbols; font.pixelSize: 46 }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: root.title; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 24; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: root.artist || root.player || "playerctl"; color: theme.fgSecondary; font.family: theme.uiFont; font.pixelSize: 20; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: root.status === "Stopped" && root.title === "Nothing playing" ? "No active player · open music or video" : root.status; color: root.status === "Playing" ? theme.accentGreen : theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 10
          radius: 5
          color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.70)
          Rectangle { width: parent.width * root.progress; height: parent.height; radius: parent.radius; color: theme.accentPink }
        }

        RowLayout {
          Layout.fillWidth: true
          Text { text: root.position; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          Item { Layout.fillWidth: true }
          Text { text: root.length; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
        }

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 14
          ControlButton { glyph: "󰒮"; onActivated: root.run("previous") }
          ControlButton { glyph: root.status === "Playing" ? "󰏤" : "󰐊"; primary: true; onActivated: root.run("play-pause") }
          ControlButton { glyph: "󰒭"; onActivated: root.run("next") }
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: "space play/pause · ←/→ previous/next · esc close"
          color: theme.fgTertiary
          font.family: theme.uiFont
          font.pixelSize: 20
        }
      }
    }
  }

  component ControlButton: Rectangle {
    property string glyph: ""
    property bool primary: false
    signal activated()
    Layout.preferredWidth: primary ? 62 : 52
    Layout.preferredHeight: primary ? 62 : 52
    radius: primary ? 18 : 15
    color: mouse.containsMouse ? theme.hoverBg : primary ? Qt.rgba(theme.accentPurple.r, theme.accentPurple.g, theme.accentPurple.b, 0.24) : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
    border.width: 1
    border.color: primary ? theme.accentPink : theme.borderGlow
    Text { anchors.centerIn: parent; text: parent.glyph; color: primary ? theme.accentPink : theme.fgPrimary; font.family: theme.symbols; font.pixelSize: primary ? 30 : 26 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
  }
}
