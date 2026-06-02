import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property string cpuText: "CPU --%"
  property int cpuValue: 0
  property string memText: "Memory --%"
  property int memValue: 0
  property string batText: "Battery unavailable"
  property int batValue: 0
  property string networkText: "Network unknown"
  property string bluetoothText: "Bluetooth unknown"
  property string audioText: "Audio unknown"
  property string mediaText: "Media idle"

  Process { id: runner; running: false }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function run(cmd, closeAfter) {
    runner.command = ["bash", "-lc", "setsid -f bash -lc " + shellQuote(cmd) + " >/dev/null 2>&1"]
    runner.running = false
    runner.running = true
    if (closeAfter) Qt.quit()
  }

  function updateStatus(text) {
    const parts = text.trim().split("|")
    root.cpuValue = parseInt(parts[0]) || 0
    root.memValue = parseInt(parts[1]) || 0
    root.batValue = parseInt(parts[2]) || 0
    const batState = parts[3] || "Unknown"
    root.audioText = parts[4] ? `Audio ${parts[4]}` : "Audio unavailable"
    root.networkText = parts[5] || "Network unknown"
    root.bluetoothText = parts[6] || "Bluetooth unknown"
    root.mediaText = parts[7] || "Media idle"
    root.cpuText = `CPU ${root.cpuValue}%`
    root.memText = `Memory ${root.memValue}%`
    root.batText = root.batValue > 0 ? `Battery ${root.batValue}% · ${batState}` : "Battery unavailable"
  }

  Process {
    id: statusProbe
    running: true
    command: ["bash", "-lc", "read _ a b c d _ < <(grep '^cpu ' /proc/stat); sleep 0.08; read _ e f g h _ < <(grep '^cpu ' /proc/stat); du=$(( (e+f+g) - (a+b+c) )); dt=$(( (e+f+g+h) - (a+b+c+d) )); cpu=$(( dt>0 ? du*100/dt : 0 )); mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{m=$2}END{printf \"%d\",(t-m)*100/t}' /proc/meminfo); bat=0; bst=Unknown; for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; bat=$(cat \"$b/capacity\" 2>/dev/null || echo 0); bst=$(cat \"$b/status\" 2>/dev/null || echo Unknown); break; done; aud=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed 's/Volume: //; s/\\[MUTED\\]/ muted/' || echo unavailable); net=$(nmcli -t -f DEVICE,STATE dev status 2>/dev/null | awk -F: '$2==\"connected\"{print $1 \" connected\"; found=1; exit} END{if(!found) print \"Network offline\"}'); bt=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/{print \"Bluetooth \" $2; exit}' || echo 'Bluetooth unknown'); media=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Media idle'); printf '%s|%s|%s|%s|%s|%s|%s|%s' \"$cpu\" \"$mem\" \"$bat\" \"$bst\" \"$aud\" \"$net\" \"$bt\" \"$media\""]
    stdout: StdioCollector { onStreamFinished: root.updateStatus(this.text) }
  }

  Timer { interval: 2500; running: true; repeat: true; onTriggered: { statusProbe.running = false; statusProbe.running = true } }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.50)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-control-center"

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Qt.quit() }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) { Qt.quit(); event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 860
      height: 620
      radius: 24
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
          spacing: 12
          Text { Layout.fillWidth: true; text: "Control Center"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 28; font.bold: true }
          Text { text: "live status · esc closes"; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 3
          rowSpacing: 12
          columnSpacing: 12
          StatusCard { title: root.cpuText; value: root.cpuValue; accent: root.cpuValue > 80 ? theme.accentRed : theme.accentTeal }
          StatusCard { title: root.memText; value: root.memValue; accent: root.memValue > 80 ? theme.accentRed : theme.accentPurple }
          StatusCard { title: root.batText; value: root.batValue; accent: root.batValue > 0 && root.batValue <= 15 ? theme.accentRed : theme.accentGreen }
        }

        GridLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          columns: 3
          rowSpacing: 12
          columnSpacing: 12

          Tile { glyph: "󰤨"; title: "Network"; subtitle: root.networkText; onActivated: root.run("nm-connection-editor", true) }
          Tile { glyph: "󰂯"; title: "Bluetooth"; subtitle: root.bluetoothText; onActivated: root.run("blueman-manager", true) }
          Tile { glyph: "󰕾"; title: "Audio"; subtitle: root.audioText; onActivated: root.run("pavucontrol", true) }
          Tile { glyph: "󰎆"; title: "Media"; subtitle: root.mediaText; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Media.qml", true) }
          Tile { glyph: "󰂚"; title: "Notifications"; subtitle: "mako history"; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Notifications.qml", true) }
          Tile { glyph: "󰃭"; title: "Calendar"; subtitle: "month view"; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Calendar.qml", true) }
          Tile { glyph: "󰐥"; title: "Power"; subtitle: "lock/logout/shutdown"; danger: true; onActivated: root.run("quickshell -p ~/.config/quickshell/current/PowerMenu.qml", true) }
        }
      }
    }
  }

  component StatusCard: Rectangle {
    property string title: ""
    property int value: 0
    property color accent: theme.accentPurple
    Layout.fillWidth: true
    Layout.preferredHeight: 104
    radius: 18
    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
    border.width: 1
    border.color: theme.borderGlow

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12
      Text { text: title; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 10
        radius: 5
        color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.62)
        Rectangle { width: parent.width * Math.max(0, Math.min(1, value / 100)); height: parent.height; radius: parent.radius; color: accent }
      }
    }
  }

  component Tile: Rectangle {
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool danger: false
    signal activated()
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 18
    color: mouse.containsMouse ? theme.hoverBg : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
    border.width: 1
    border.color: danger ? theme.accentRed : theme.borderGlow

    RowLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 14
      Text { text: glyph; color: danger ? theme.accentRed : theme.accentPink; font.family: theme.symbols; font.pixelSize: 32 }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text { Layout.fillWidth: true; text: title; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true; elide: Text.ElideRight }
        Text { Layout.fillWidth: true; text: subtitle; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20; elide: Text.ElideRight }
      }
    }

    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
  }
}
