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

  readonly property string icoBtOn: String.fromCodePoint(0xf294)
  readonly property string icoVol3: String.fromCodePoint(0xf028)
  readonly property string icoMute: String.fromCodePoint(0xeee8)
  readonly property int barHeight: 44

  property int activeWs: 1
  property var existingWs: [1, 2, 3, 4, 5]

  property int cpuVal: 0
  property int memVal: 0
  property int batVal: 0
  property string batState: "Unknown"

  property string netIcon: "󰤯"
  property string btIcon: "󰂲"
  property string audioIcon: icoVol3

  property string hh: "--"
  property string mm: "--"
  property string dd: "--"
  property string mon: "---"

  Process {
    id: runner
    running: false
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
  }

  function run(cmd) {
    runner.command = ["bash", "-lc", "setsid -f bash -lc " + shellQuote(cmd) + " >/dev/null 2>&1"];
    runner.running = false;
    runner.running = true;
  }

  Process {
    id: telemetryProbe
    running: false
    command: ["bash", "-lc",
      "read _ a b c d _ < <(grep '^cpu ' /proc/stat); "
      + "sleep 0.15; "
      + "read _ e f g h _ < <(grep '^cpu ' /proc/stat); "
      + "du=$(( (e+f+g) - (a+b+c) )); dt=$(( (e+f+g+h) - (a+b+c+d) )); "
      + "cpu=$(( dt>0 ? du*100/dt : 0 )); "
      + "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{m=$2}END{printf \"%d\",(t-m)*100/t}' /proc/meminfo); "
      + "bat=0; bst=Unknown; "
      + "if [ -d /sys/class/power_supply/BAT0 ]; then "
      + "  bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0); "
      + "  bst=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown); "
      + "elif [ -d /sys/class/power_supply/BAT1 ]; then "
      + "  bat=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0); "
      + "  bst=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Unknown); "
      + "fi; "
      + "printf '%d|%d|%d|%s|%s|%s|%s|%s' "
      + "  \"$cpu\" \"$mem\" \"$bat\" \"$bst\" "
      + "  \"$(date +%H)\" \"$(date +%M)\" \"$(date +%d)\" \"$(date +%b | tr a-z A-Z)\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.split("|");
        if (parts.length === 8) {
          root.cpuVal = parseInt(parts[0]) || 0;
          root.memVal = parseInt(parts[1]) || 0;
          root.batVal = parseInt(parts[2]) || 0;
          root.batState = parts[3] || "Unknown";
          root.hh = parts[4];
          root.mm = parts[5];
          root.dd = parts[6];
          root.mon = parts[7];
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      telemetryProbe.running = false;
      telemetryProbe.running = true;
    }
  }

  Process {
    id: workspaceProbe
    running: false
    command: ["bash", "-lc",
      "act=$(hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | head -1); "
      + "ids=$(hyprctl workspaces -j 2>/dev/null | tr ',' '\\n' | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | sort -nu | paste -sd,); "
      + "printf '%s|%s' \"${act:-1}\" \"${ids:-1}\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.split("|");
        if (parts.length === 2) {
          root.activeWs = parseInt(parts[0]) || 1;
          const present = parts[1].split(",").map(s => parseInt(s)).filter(n => !isNaN(n));
          root.existingWs = [...new Set([...present, 1, 2, 3, 4, 5])].sort((a, b) => a - b).slice(0, 10);
        }
      }
    }
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      workspaceProbe.running = false;
      workspaceProbe.running = true;
    }
  }

  Process {
    id: networkProbe
    running: false
    command: ["bash", "-lc",
      "type=none; "
      + "if ip -o link show | awk -F': ' '{print $2}' | grep -qE '^(en|eth)'; then "
      + "  if ip -o addr show | grep -qE '^[0-9]+: (en|eth)[^ ]*.*inet '; then type=eth; fi; "
      + "fi; "
      + "if [ \"$type\" = none ]; then "
      + "  s=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"*\"{print $2; exit}'); "
      + "  if [ -n \"$s\" ]; then type=wifi:$s; fi; "
      + "fi; printf '%s' \"$type\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const status = this.text.trim();
        if (status === "eth") root.netIcon = "󰀂";
        else if (status.startsWith("wifi:")) {
          const signal = parseInt(status.split(":")[1]) || 0;
          const ramp = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
          root.netIcon = ramp[signal >= 80 ? 4 : signal >= 60 ? 3 : signal >= 40 ? 2 : signal >= 20 ? 1 : 0];
        } else root.netIcon = "󰤮";
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      networkProbe.running = false;
      networkProbe.running = true;
    }
  }

  Process {
    id: bluetoothProbe
    running: false
    command: ["bash", "-lc",
      "if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then p=1; else p=0; fi; "
      + "c=$(bluetoothctl devices Connected 2>/dev/null | wc -l); "
      + "if [ \"$p\" = 0 ]; then echo off; "
      + "elif [ \"$c\" -gt 0 ]; then echo on-conn; "
      + "else echo on; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        const status = this.text.trim();
        if (status === "off") root.btIcon = "󰂲";
        else if (status === "on-conn") root.btIcon = "󰂱";
        else root.btIcon = root.icoBtOn;
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      bluetoothProbe.running = false;
      bluetoothProbe.running = true;
    }
  }

  Process {
    id: audioProbe
    running: false
    command: ["bash", "-lc", "m=$(pamixer --get-mute 2>/dev/null || echo false); if [ \"$m\" = true ]; then echo mute; else echo on; fi"]
    stdout: StdioCollector {
      onStreamFinished: root.audioIcon = this.text.trim() === "mute" ? root.icoMute : root.icoVol3
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      audioProbe.running = false;
      audioProbe.running = true;
    }
  }

  function batteryIcon() {
    const charging = root.batState === "Charging" || root.batState === "Full";
    const capacity = root.batVal;
    if (charging) {
      const icons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"];
      return icons[Math.min(9, Math.floor(capacity / 10))];
    }
    const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
    return icons[Math.min(9, Math.floor(capacity / 10))];
  }

  PanelWindow {
    id: bar
    color: "transparent"
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: root.barHeight
    exclusiveZone: root.barHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-lotus-bar"

    Rectangle {
      anchors.fill: parent
      color: root.theme.bg

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "静"
        color: Qt.rgba(0.33, 0.33, 0.39, 0.07)
        font.family: root.theme.serif
        font.pixelSize: root.barHeight + 6
        font.weight: Font.Light
        z: 0
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: root.theme.sep
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.hh + ":" + root.mm
          color: root.theme.ink
          font.family: root.theme.serif
          font.pixelSize: 20
          font.letterSpacing: 2
          font.weight: Font.Light
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: 10
          color: root.theme.sumi
          opacity: 0.4
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.dd + " " + root.mon
          color: root.theme.sumi
          font.family: root.theme.serif
          font.pixelSize: 20
          font.letterSpacing: 2
          font.italic: true
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 4

        Module {
          glyph: "悟"
          color: root.theme.seal
          fontFamily: root.theme.serif
          fontSize: 20
          onActivated: root.run("quickshell -p ~/.config/quickshell/themes/lotus/QuickApps.qml")
          onRightActivated: root.run("ghostty")
        }

        Separator {}

        Repeater {
          model: 10
          delegate: Workspace {
            required property int index
            wsId: index + 1
            label: root.theme.indexKanji(index + 1)
            active: root.activeWs === index + 1
            present: root.existingWs.indexOf(index + 1) !== -1
            onActivated: root.run("hyprctl dispatch workspace " + (index + 1))
          }
        }

        Item { Layout.fillWidth: true }

        Separator {}

        Module {
          glyph: "󰍛"
          color: root.cpuVal > 80 ? root.theme.seal : root.theme.ink
          onActivated: root.run("ghostty -e htop")
        }

        Tray { parentWindow: bar }

        Module {
          glyph: root.netIcon
          onActivated: root.run("nm-connection-editor")
        }

        Module {
          glyph: root.btIcon
          onActivated: root.run("blueman-manager")
        }

        Module {
          glyph: root.audioIcon
          onActivated: root.run("pavucontrol")
          onRightActivated: root.run("pamixer -t")
        }

        Module {
          glyph: root.batteryIcon()
          color: root.batVal <= 10 ? root.theme.seal : root.batVal <= 20 ? root.theme.indigo : root.theme.ink
          onActivated: root.run("quickshell -p ~/.config/quickshell/themes/lotus/PowerMenu.qml")
        }
      }
    }
  }

  component Separator: Rectangle {
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 1
    Layout.preferredHeight: 20
    Layout.leftMargin: 4
    Layout.rightMargin: 4
    color: root.theme.sep
  }

  component Tray: RowLayout {
    required property var parentWindow

    Layout.alignment: Qt.AlignVCenter
    spacing: 0
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
    Layout.preferredHeight: root.barHeight

    Rectangle {
      anchors.fill: parent
      anchors.topMargin: 3
      anchors.bottomMargin: 3
      color: mouse.containsMouse ? Qt.rgba(0.33, 0.33, 0.39, 0.06) : "transparent"
      Behavior on color { ColorAnimation { duration: 180 } }
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
    property color color: root.theme.ink
    property string fontFamily: root.theme.mono
    property int fontSize: 20

    signal activated()
    signal rightActivated()

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 40
    Layout.preferredHeight: root.barHeight

    Rectangle {
      anchors.fill: parent
      anchors.topMargin: 3
      anchors.bottomMargin: 3
      color: mouse.containsMouse ? Qt.rgba(0.33, 0.33, 0.39, 0.06) : "transparent"
      Behavior on color { ColorAnimation { duration: 180 } }
    }

    Text {
      anchors.centerIn: parent
      text: parent.glyph
      color: parent.color
      font.family: parent.fontFamily
      font.pixelSize: parent.fontSize
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: event => {
        if (event.button === Qt.RightButton) parent.rightActivated();
        else parent.activated();
      }
    }
  }

  component Workspace: Item {
    property int wsId: 0
    property string label: ""
    property bool active: false
    property bool present: false

    signal activated()

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 32
    Layout.preferredHeight: root.barHeight

    Text {
      id: kanji
      anchors.centerIn: parent
      text: parent.label
      color: parent.active ? root.theme.seal : parent.present ? root.theme.ink : root.theme.sumi
      opacity: parent.active ? 1.0 : parent.present ? 0.75 : 0.35
      font.family: root.theme.serif
      font.pixelSize: 20
      font.weight: Font.Light
      Behavior on color { ColorAnimation { duration: 220 } }
      Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: kanji.bottom
      anchors.topMargin: -1
      width: 3
      height: 3
      radius: 1.5
      color: root.theme.seal
      opacity: parent.active ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.activated()
    }
  }
}
