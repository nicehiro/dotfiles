import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
  id: root
  required property QtObject theme

  readonly property int barHeight: 48
  property int cpuVal: 0
  property int memVal: 0
  property int batVal: 0
  property string batState: "Unknown"
  property string netIcon: "󰤯"
  property string btIcon: "󰂲"
  property string audioIcon: "󰕾"
  property string clockText: "--:--"

  Process { id: runner; running: false }
  function shellQuote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'" }
  function run(cmd) {
    runner.command = ["bash", "-lc", "setsid -f bash -lc " + shellQuote(cmd) + " >/dev/null 2>&1"]
    runner.running = false
    runner.running = true
  }

  Process {
    id: telemetryProbe
    running: false
    command: ["bash", "-lc",
      "read _ a b c d _ < <(grep '^cpu ' /proc/stat); sleep 0.12; " +
      "read _ e f g h _ < <(grep '^cpu ' /proc/stat); " +
      "du=$(( (e+f+g) - (a+b+c) )); dt=$(( (e+f+g+h) - (a+b+c+d) )); " +
      "cpu=$(( dt>0 ? du*100/dt : 0 )); " +
      "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{m=$2}END{printf \"%d\",(t-m)*100/t}' /proc/meminfo); " +
      "bat=0; bst=Unknown; for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; bat=$(cat \"$b/capacity\" 2>/dev/null || echo 0); bst=$(cat \"$b/status\" 2>/dev/null || echo Unknown); break; done; " +
      "printf '%d|%d|%d|%s' \"$cpu\" \"$mem\" \"$bat\" \"$bst\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.split("|")
        if (parts.length === 4) {
          root.cpuVal = parseInt(parts[0]) || 0
          root.memVal = parseInt(parts[1]) || 0
          root.batVal = parseInt(parts[2]) || 0
          root.batState = parts[3] || "Unknown"
        }
      }
    }
  }

  Process {
    id: networkProbe
    running: false
    command: ["bash", "-lc", "if ip -o addr show | grep -qE '^[0-9]+: (en|eth)[^ ]*.*inet '; then echo eth; else s=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"*\"{print $2; exit}'); [ -n \"$s\" ] && echo wifi:$s || echo none; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        const status = this.text.trim()
        if (status === "eth") root.netIcon = "󰈀"
        else if (status.startsWith("wifi:")) {
          const signal = parseInt(status.split(":")[1]) || 0
          const ramp = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
          root.netIcon = ramp[signal >= 80 ? 4 : signal >= 60 ? 3 : signal >= 40 ? 2 : signal >= 20 ? 1 : 0]
        } else root.netIcon = "󰤮"
      }
    }
  }

  Process {
    id: bluetoothProbe
    running: false
    command: ["bash", "-lc", "if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then c=$(bluetoothctl devices Connected 2>/dev/null | wc -l); [ \"$c\" -gt 0 ] && echo conn || echo on; else echo off; fi"]
    stdout: StdioCollector { onStreamFinished: root.btIcon = this.text.trim() === "conn" ? "󰂱" : this.text.trim() === "on" ? "󰂯" : "󰂲" }
  }

  Process {
    id: audioProbe
    running: false
    command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ muted=($0 ~ /MUTED/); vol=int($2 * 100); if (muted) print \"mute\"; else if (vol >= 66) print \"high\"; else if (vol >= 33) print \"mid\"; else print \"low\" }'"]
    stdout: StdioCollector {
      onStreamFinished: {
        const status = this.text.trim()
        root.audioIcon = status === "mute" ? "󰝟" : status === "high" ? "󰕾" : status === "mid" ? "󰖀" : "󰕿"
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      const now = new Date()
      const day = now.toLocaleDateString(Qt.locale(), "ddd dd MMM")
      const time = now.toLocaleTimeString(Qt.locale(), "HH:mm")
      root.clockText = `${day}  ${time}`
      telemetryProbe.running = false; telemetryProbe.running = true
    }
  }
  Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { networkProbe.running = false; networkProbe.running = true } }
  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { bluetoothProbe.running = false; bluetoothProbe.running = true } }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { audioProbe.running = false; audioProbe.running = true } }

  function batteryIcon() {
    const charging = root.batState === "Charging" || root.batState === "Full"
    const icons = charging ? ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"] : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    return icons[Math.min(9, Math.max(0, Math.floor(root.batVal / 10)))]
  }

  PanelWindow {
    id: bar
    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: root.barHeight
    exclusiveZone: root.barHeight
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-yahr-bar"

    Rectangle {
      anchors.fill: parent
      color: root.theme.bg
      border.width: 0

      Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: root.theme.borderGlow }
      Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: Qt.rgba(1, 1, 1, 0.10) }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "☾"
        color: Qt.rgba(root.theme.accentPurple.r, root.theme.accentPurple.g, root.theme.accentPurple.b, 0.10)
        font.pixelSize: root.barHeight + 8
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Module { glyph: ""; color: root.theme.accentPink; onActivated: root.run("quickshell -p ~/.config/quickshell/current/QuickApps.qml"); onRightActivated: root.run("ghostty") }
        Separator {}
        WorkspaceBar { theme: root.theme }
        Item { Layout.fillWidth: true }
        ClockPill { text: root.clockText; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Calendar.qml") }
        Item { Layout.fillWidth: true }
        Module { glyph: "󰍛"; color: root.cpuVal > 80 ? root.theme.accentRed : root.theme.fgPrimary; onActivated: root.run("ghostty -e htop") }
        Module { glyph: "󰎆"; color: root.theme.accentPink; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Media.qml"); onRightActivated: root.run("playerctl play-pause") }
        Module { glyph: "󰒓"; color: root.theme.accentPurple; onActivated: root.run("quickshell -p ~/.config/quickshell/current/ControlCenter.qml") }
        Module { glyph: "󰂚"; color: root.theme.accentPink; onActivated: root.run("quickshell -p ~/.config/quickshell/current/Notifications.qml"); onRightActivated: root.run("makoctl dismiss --all") }
        Tray { parentWindow: bar }
        Module { glyph: root.netIcon; onActivated: root.run("nm-connection-editor") }
        Module { glyph: root.btIcon; onActivated: root.run("blueman-manager") }
        Module { glyph: root.audioIcon; onActivated: root.run("pavucontrol"); onRightActivated: root.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") }
        Module { glyph: root.batteryIcon(); color: root.batVal > 0 && root.batVal <= 15 ? root.theme.accentRed : root.theme.fgPrimary; onActivated: root.run("quickshell -p ~/.config/quickshell/current/PowerMenu.qml") }
      }
    }
  }

  component Separator: Rectangle {
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 1
    Layout.preferredHeight: 20
    color: root.theme.borderGlow
  }

  component ClockPill: Rectangle {
    property string text: ""
    signal activated()
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: label.implicitWidth + 34
    Layout.preferredHeight: 36
    radius: 9
    color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.68)
    border.width: 1
    border.color: root.theme.borderGlow
    Text { id: label; anchors.centerIn: parent; text: parent.text; color: root.theme.fgPrimary; font.family: root.theme.uiFont; font.pixelSize: 20 }
    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
  }

  component Tray: RowLayout {
    required property var parentWindow

    Layout.alignment: Qt.AlignVCenter
    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
      model: SystemTray.items

      TrayItem {
        required property var modelData
        item: modelData
        parentWindow: parent.parentWindow
      }
    }
  }

  component TrayItem: Item {
    required property var item
    required property var parentWindow

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 34
    Layout.preferredHeight: 40

    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: 8
      color: mouse.containsMouse ? root.theme.hoverBg : "transparent"
      Behavior on color { ColorAnimation { duration: 160 } }
    }

    IconImage {
      anchors.centerIn: parent
      width: 22
      height: 22
      source: Quickshell.iconPath(parent.item.icon)
      asynchronous: true
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: event => {
        if (event.button === Qt.RightButton && parent.item.hasMenu) {
          const point = parent.mapToItem(parent.parentWindow.contentItem, width / 2, height)
          parent.item.display(parent.parentWindow, point.x, point.y)
        } else parent.item.activate()
      }
    }
  }

  component Module: Item {
    property string glyph: ""
    property color color: root.theme.fgPrimary
    signal activated()
    signal rightActivated()
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 40
    Layout.preferredHeight: 40
    Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 8; color: mouse.containsMouse ? root.theme.hoverBg : "transparent"; Behavior on color { ColorAnimation { duration: 160 } } }
    Text { anchors.centerIn: parent; text: parent.glyph; color: parent.color; font.family: root.theme.symbols; font.pixelSize: root.theme.fontSizeIcon }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: event => { if (event.button === Qt.RightButton) parent.rightActivated(); else parent.activated() }
    }
  }
}
