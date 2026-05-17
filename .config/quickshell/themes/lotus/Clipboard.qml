import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  readonly property color paper: "#f1e9d2"
  readonly property color ink: "#545464"
  readonly property color inkDeep: "#43436c"
  readonly property color sumi: "#8a8980"
  readonly property color indigo: "#4d699b"
  readonly property color seal: "#c84053"
  readonly property color wash: "#e6dcc0"
  readonly property string serif: "serif"
  readonly property string mono: "IoskeleyMono Nerd Font"

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
        root.entries = this.text.split("\n").filter(line => line.length > 0);
        root.selectedIndex = 0;
      }
    }
  }

  Process {
    id: copyProc
    running: false
    onExited: Qt.quit()
  }

  Process {
    id: clearProc
    running: false
    onExited: Qt.quit()
  }

  function clampSelection() {
    if (filteredEntries.length === 0) selectedIndex = 0;
    else selectedIndex = Math.max(0, Math.min(selectedIndex, filteredEntries.length - 1));
  }

  function move(delta) {
    if (filteredEntries.length === 0) return;
    selectedIndex = (selectedIndex + delta + filteredEntries.length) % filteredEntries.length;
  }

  function copySelected() {
    if (filteredEntries.length === 0) return;
    copyProc.command = ["bash", "-lc", "printf '%s' \"$1\" | cliphist decode | wl-copy", "clipboard", filteredEntries[selectedIndex]];
    copyProc.running = true;
  }

  function clearHistory() {
    clearProc.command = ["bash", "-lc", "cliphist wipe && notify-send 'Clipboard history cleared'"];
    clearProc.running = true;
  }

  onQueryChanged: {
    selectedIndex = 0;
    clampSelection();
  }

  PanelWindow {
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: Qt.rgba(0.945, 0.914, 0.824, 0.94)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-lotus-clipboard"

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.RightButton
      onClicked: Qt.quit()
      onWheel: event => {
        root.move(event.angleDelta.y > 0 ? -1 : 1);
        event.accepted = true;
      }
    }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          Qt.quit();
          event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
          root.move(-1);
          event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) {
          root.move(1);
          event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
          root.move(-6);
          event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
          root.move(6);
          event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.copySelected();
          event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
          root.query = root.query.slice(0, -1);
          event.accepted = true;
        } else if (event.key === Qt.Key_U && event.modifiers & Qt.ControlModifier) {
          root.query = "";
          event.accepted = true;
        } else if (event.key === Qt.Key_W && event.modifiers & Qt.ControlModifier) {
          root.query = root.query.replace(/\s*\S+\s*$/, "");
          event.accepted = true;
        } else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.MetaModifier)) {
          root.query += event.text;
          event.accepted = true;
        }
      }
    }

    Text {
      anchors.centerIn: parent
      text: "写"
      color: Qt.rgba(0.33, 0.33, 0.39, 0.055)
      font.family: root.serif
      font.pixelSize: 380
      font.weight: Font.Light
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.width - 96, 860)
      height: Math.min(parent.height - 120, 620)
      radius: 0
      color: Qt.rgba(0.945, 0.914, 0.824, 0.86)
      border.width: 1
      border.color: Qt.rgba(0.33, 0.33, 0.39, 0.16)

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
              text: "CLIPBOARD"
              color: root.ink
              font.family: root.serif
              font.pixelSize: 22
              font.letterSpacing: 5
              font.weight: Font.Light
            }

            Text {
              text: "type to filter, enter to copy, ctrl-u to clear query, right-click/esc to close"
              color: root.sumi
              font.family: root.serif
              font.pixelSize: 20
              font.italic: true
              font.letterSpacing: 1.2
            }
          }

          Rectangle {
            Layout.preferredWidth: 124
            Layout.preferredHeight: 44
            color: clearMouse.containsMouse ? root.ink : "transparent"
            border.width: 1
            border.color: root.seal

            Text {
              anchors.centerIn: parent
              text: "CLEAR"
              color: clearMouse.containsMouse ? root.paper : root.seal
              font.family: root.serif
              font.pixelSize: 20
              font.letterSpacing: 2
            }

            MouseArea {
              id: clearMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearHistory()
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 58
          color: root.wash
          border.width: 1
          border.color: Qt.rgba(0.33, 0.33, 0.39, 0.16)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Text {
              text: "探"
              color: root.seal
              font.family: root.serif
              font.pixelSize: 20
              font.weight: Font.Light
            }

            Text {
              Layout.fillWidth: true
              text: root.query.length > 0 ? root.query : "search clipboard history"
              color: root.query.length > 0 ? root.ink : root.sumi
              opacity: root.query.length > 0 ? 1 : 0.7
              font.family: root.serif
              font.pixelSize: 20
              font.italic: root.query.length === 0
              elide: Text.ElideRight
            }

            Text {
              text: `${root.filteredEntries.length}/${root.entries.length}`
              color: root.sumi
              font.family: root.serif
              font.pixelSize: 20
              font.letterSpacing: 1.5
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(0.33, 0.33, 0.39, 0.16)
        }

        ListView {
          id: list
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: root.filteredEntries
          spacing: 6
          currentIndex: root.selectedIndex
          boundsBehavior: Flickable.StopAtBounds
          highlightMoveDuration: 140
          onCountChanged: root.clampSelection()
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

          delegate: Rectangle {
            id: row
            required property string modelData
            required property int index
            readonly property bool selected: root.selectedIndex === index

            width: ListView.view.width
            height: Math.max(42, preview.implicitHeight + 18)
            color: selected ? root.ink : mouse.containsMouse ? Qt.rgba(0.33, 0.33, 0.39, 0.055) : "transparent"
            border.width: selected ? 0 : 1
            border.color: Qt.rgba(0.33, 0.33, 0.39, 0.08)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 12

              Text {
                Layout.preferredWidth: 52
                text: String(index + 1).padStart(2, "0")
                color: selected ? Qt.rgba(0.945, 0.914, 0.824, 0.66) : root.sumi
                font.family: root.serif
                font.pixelSize: 20
                font.letterSpacing: 1.5
              }

              Text {
                id: preview
                Layout.fillWidth: true
                text: row.modelData.replace(/\t/g, "  ")
                color: selected ? root.paper : root.ink
                font.family: root.mono
                font.pixelSize: 20
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
              }

              Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: 4
                radius: 2
                color: root.seal
                opacity: selected ? 1 : 0
              }
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

          Text {
            anchors.centerIn: parent
            visible: root.filteredEntries.length === 0
            text: root.entries.length === 0 ? "clipboard history is empty" : "no matching entries"
            color: root.sumi
            font.family: root.serif
            font.pixelSize: 20
            font.italic: true
          }
        }
      }
    }
  }
}
