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

  property int selectedIndex: 0
  readonly property var actions: [
    { "name": "LOCK", "kanji": "鎖", "hint": "hyprlock", "cmd": "hyprlock" },
    { "name": "LOGOUT", "kanji": "出", "hint": "exit Hyprland", "cmd": "hyprctl dispatch exit" },
    { "name": "SUSPEND", "kanji": "眠", "hint": "systemctl suspend", "cmd": "systemctl suspend" },
    { "name": "REBOOT", "kanji": "巡", "hint": "systemctl reboot", "cmd": "systemctl reboot" },
    { "name": "SHUTDOWN", "kanji": "終", "hint": "systemctl poweroff", "cmd": "systemctl poweroff" }
  ]

  Process {
    id: runner
    running: false
    onExited: Qt.quit()
  }

  function move(delta) {
    selectedIndex = (selectedIndex + delta + actions.length) % actions.length;
  }

  function runSelected() {
    const action = actions[selectedIndex];
    runner.command = ["bash", "-lc", action.cmd];
    runner.running = true;
  }

  PanelWindow {
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: Qt.rgba(0.945, 0.914, 0.824, 0.96)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-lotus-power"

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
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
          Qt.quit();
          event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Up || event.key === Qt.Key_K) {
          root.move(-1);
          event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) {
          root.move(1);
          event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          root.runSelected();
          event.accepted = true;
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
          root.selectedIndex = event.key - Qt.Key_1;
          root.runSelected();
          event.accepted = true;
        }
      }
    }

    Text {
      anchors.centerIn: parent
      text: "静"
      color: Qt.rgba(0.33, 0.33, 0.39, 0.06)
      font.family: root.serif
      font.pixelSize: 360
      font.weight: Font.Light
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 96
      width: 128
      height: 1
      color: root.ink
      opacity: 0.45
    }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 32

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "POWER"
          color: root.ink
          font.family: root.serif
          font.pixelSize: 28
          font.letterSpacing: 6
          font.weight: Font.Light
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "choose with hjkl / arrows, enter to confirm, esc to close"
          color: root.sumi
          font.family: root.serif
          font.pixelSize: 20
          font.italic: true
          font.letterSpacing: 1.5
        }
      }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 18

        Repeater {
          model: root.actions.length

          delegate: Item {
            id: actionItem
            required property int index
            readonly property var action: root.actions[index]
            readonly property bool selected: root.selectedIndex === index

            Layout.preferredWidth: 148
            Layout.preferredHeight: 188

            Rectangle {
              anchors.fill: parent
              radius: 999
              color: actionItem.selected ? root.ink : Qt.rgba(0.902, 0.863, 0.753, 0.56)
              border.width: 1
              border.color: actionItem.selected ? root.inkDeep : Qt.rgba(0.33, 0.33, 0.39, 0.16)
              Behavior on color { ColorAnimation { duration: 180 } }
              Behavior on border.color { ColorAnimation { duration: 180 } }
            }

            Column {
              anchors.centerIn: parent
              spacing: 10

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionItem.action.kanji
                color: actionItem.selected ? root.paper : root.ink
                font.family: root.serif
                font.pixelSize: 34
                font.weight: Font.Light
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionItem.action.name
                color: actionItem.selected ? root.paper : root.ink
                font.family: root.serif
                font.pixelSize: 20
                font.letterSpacing: 2
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 124
                horizontalAlignment: Text.AlignHCenter
                text: actionItem.action.hint
                color: actionItem.selected ? Qt.rgba(0.945, 0.914, 0.824, 0.72) : root.sumi
                font.family: root.serif
                font.pixelSize: 20
                font.italic: true
                wrapMode: Text.WordWrap
              }
            }

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 16
              width: 4
              height: 4
              radius: 2
              color: root.seal
              opacity: actionItem.selected ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.selectedIndex = actionItem.index
              onClicked: root.runSelected()
            }
          }
        }
      }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 96
      width: 128
      height: 1
      color: root.ink
      opacity: 0.45
    }
  }
}
