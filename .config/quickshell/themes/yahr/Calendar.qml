import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
  id: root
  Theme { id: theme }

  property date shownDate: new Date()
  readonly property int year: shownDate.getFullYear()
  readonly property int month: shownDate.getMonth()
  readonly property date today: new Date()
  readonly property var weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  function monthName() {
    return shownDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
  }

  function daysInMonth() {
    return new Date(year, month + 1, 0).getDate()
  }

  function firstWeekday() {
    return new Date(year, month, 1).getDay()
  }

  function dayForCell(index) {
    const day = index - firstWeekday() + 1
    return day >= 1 && day <= daysInMonth() ? day : 0
  }

  function isToday(day) {
    return day > 0 && day === today.getDate() && month === today.getMonth() && year === today.getFullYear()
  }

  function shiftMonth(delta) {
    shownDate = new Date(year, month + delta, 1)
  }

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(theme.bgCrust.r, theme.bgCrust.g, theme.bgCrust.b, 0.50)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-yahr-calendar"

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: Qt.quit() }

    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) { Qt.quit(); event.accepted = true }
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) { root.shiftMonth(-1); event.accepted = true }
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) { root.shiftMonth(1); event.accepted = true }
        else if (event.key === Qt.Key_T) { root.shownDate = new Date(); event.accepted = true }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 560
      height: 500
      radius: 22
      color: theme.panelBg
      border.width: 1
      border.color: theme.borderGlow
      antialiasing: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text {
            Layout.fillWidth: true
            text: root.monthName()
            color: theme.fgPrimary
            font.family: theme.uiFont
            font.pixelSize: 28
            font.bold: true
          }

          NavButton { label: "‹"; onActivated: root.shiftMonth(-1) }
          NavButton { label: "Today"; wide: true; onActivated: root.shownDate = new Date() }
          NavButton { label: "›"; onActivated: root.shiftMonth(1) }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Repeater {
            model: root.weekdays
            Text {
              required property string modelData
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              color: theme.accentPink
              font.family: theme.uiFont
              font.pixelSize: 20
              font.bold: true
            }
          }
        }

        GridLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          columns: 7
          rowSpacing: 8
          columnSpacing: 8

          Repeater {
            model: 42
            delegate: Rectangle {
              id: cell
              required property int index
              readonly property int day: root.dayForCell(index)
              readonly property bool currentDay: root.isToday(day)
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: 12
              color: currentDay ? Qt.rgba(theme.accentPurple.r, theme.accentPurple.g, theme.accentPurple.b, 0.30)
                : mouse.containsMouse && day > 0 ? theme.hoverBg
                : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, day > 0 ? 0.46 : 0.16)
              border.width: currentDay || (mouse.containsMouse && day > 0) ? 1 : 0
              border.color: currentDay ? theme.accentPink : theme.borderGlow

              Text {
                anchors.centerIn: parent
                text: cell.day > 0 ? cell.day.toString() : ""
                color: cell.currentDay ? theme.fgPrimary : theme.fgSecondary
                font.family: theme.uiFont
                font.pixelSize: 20
                font.bold: cell.currentDay
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: cell.day > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: event => { if (event.button === Qt.RightButton) Qt.quit() }
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: "←/→ change month · t today · esc close"
          color: theme.fgTertiary
          font.family: theme.uiFont
          font.pixelSize: 20
        }
      }
    }
  }

  component NavButton: Rectangle {
    property string label: ""
    property bool wide: false
    signal activated()
    Layout.preferredWidth: wide ? 92 : 44
    Layout.preferredHeight: 40
    radius: 10
    color: mouse.containsMouse ? theme.hoverBg : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.62)
    border.width: 1
    border.color: theme.borderGlow

    Text {
      anchors.centerIn: parent
      text: parent.label
      color: theme.fgPrimary
      font.family: theme.uiFont
      font.pixelSize: 20
      font.bold: true
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.activated()
    }
  }
}
