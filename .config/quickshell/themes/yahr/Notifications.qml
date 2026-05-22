import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property int selectedIndex: 0
  property var notifications: []
  readonly property int activeCount: notifications.filter(item => item.source === "active").length

  function loadItems(text) {
    try {
      const parsed = JSON.parse(text || "[]")
      root.notifications = parsed.map(item => ({
        id: item.id || 0,
        source: item.source || "history",
        summary: item.summary || "Notification",
        body: item.body || "",
        app: item.app_name || item.desktop_entry || item.app_icon || "mako",
        urgency: item.urgency || "normal"
      }))
    } catch (e) {
      root.notifications = []
    }
    root.selectedIndex = 0
  }

  function move(delta) {
    if (notifications.length === 0) return
    selectedIndex = (selectedIndex + delta + notifications.length) % notifications.length
  }

  function selectedId() {
    if (notifications.length === 0) return 0
    return notifications[selectedIndex].id || 0
  }

  function runMako(args) {
    action.command = ["bash", "-lc", "makoctl " + args + " >/dev/null 2>&1 || true"]
    action.running = false
    action.running = true
  }

  Process { id: action; running: false; onExited: loader.running = true }

  Process {
    id: loader
    running: true
    command: ["bash", "-lc", "python3 - <<'PY'\nimport json, subprocess\nitems = []\nfor source, cmd in [('active', ['makoctl', 'list', '-j']), ('history', ['makoctl', 'history', '-j'])]:\n    try:\n        data = json.loads(subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL))\n    except Exception:\n        data = []\n    for item in data:\n        item['source'] = source\n        items.append(item)\nprint(json.dumps(items[:30]))\nPY"]
    stdout: StdioCollector { onStreamFinished: root.loadItems(this.text) }
  }

  Timer { interval: 3000; running: true; repeat: true; onTriggered: { loader.running = false; loader.running = true } }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.50)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-notifications"

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
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) { root.move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) { root.move(1); event.accepted = true }
        else if (event.key === Qt.Key_D) { root.runMako("dismiss -n " + root.selectedId()); event.accepted = true }
        else if (event.key === Qt.Key_R) { root.runMako("restore"); event.accepted = true }
        else if (event.key === Qt.Key_C) { root.runMako("dismiss --all"); event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.width - 120, 920)
      height: Math.min(parent.height - 120, 640)
      radius: 24
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow
      antialiasing: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
          Layout.fillWidth: true
          spacing: 12
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: "Notifications"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 28; font.bold: true }
            Text { text: `${root.activeCount} active · ${root.notifications.length} total with history`; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          }
          HeaderButton { label: "Restore"; onActivated: root.runMako("restore") }
          HeaderButton { label: "Clear"; danger: true; onActivated: root.runMako("dismiss --all") }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          ListView {
            anchors.fill: parent
            clip: true
            model: root.notifications
            currentIndex: root.selectedIndex
            spacing: 8

            delegate: Rectangle {
              id: row
              required property int index
              required property var modelData
              width: ListView.view.width
              height: Math.max(96, content.implicitHeight + 24)
              radius: 16
              color: index === root.selectedIndex ? theme.hoverBg : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.46)
              border.width: index === root.selectedIndex ? 1 : 0
              border.color: theme.borderGlow

              RowLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                  text: row.modelData.source === "active" ? "󰂚" : "󰋚"
                  color: row.modelData.urgency === "critical" ? theme.accentRed : row.modelData.source === "active" ? theme.accentPink : theme.fgTertiary
                  font.family: theme.symbols
                  font.pixelSize: 28
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 4
                  Text { text: row.modelData.summary; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                  Text { text: row.modelData.body || row.modelData.app; color: theme.fgSecondary; font.family: theme.uiFont; font.pixelSize: 20; elide: Text.ElideRight; wrapMode: Text.NoWrap; Layout.fillWidth: true }
                  Text { text: `${row.modelData.source} · ${row.modelData.app}`; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20; elide: Text.ElideRight; Layout.fillWidth: true }
                }
              }

              MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = row.index; onClicked: root.runMako("dismiss -n " + row.modelData.id) }
            }
          }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            visible: root.notifications.length === 0
            Text { Layout.alignment: Qt.AlignHCenter; text: "󰂜"; color: theme.accentPink; font.family: theme.symbols; font.pixelSize: 42 }
            Text { Layout.alignment: Qt.AlignHCenter; text: "No notifications"; color: theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: "mako history will appear here"; color: theme.fgTertiary; font.family: theme.uiFont; font.pixelSize: 20 }
          }
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: "j/k select · d dismiss · r restore · c clear · esc close"
          color: theme.fgTertiary
          font.family: theme.uiFont
          font.pixelSize: 20
        }
      }
    }
  }

  component HeaderButton: Rectangle {
    property string label: ""
    property bool danger: false
    signal activated()
    Layout.preferredWidth: 112
    Layout.preferredHeight: 42
    radius: 11
    color: mouse.containsMouse ? theme.hoverBg : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
    border.width: 1
    border.color: danger ? theme.accentRed : theme.borderGlow
    Text { anchors.centerIn: parent; text: parent.label; color: danger ? theme.accentRed : theme.fgPrimary; font.family: theme.uiFont; font.pixelSize: 20; font.bold: true }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
  }
}
