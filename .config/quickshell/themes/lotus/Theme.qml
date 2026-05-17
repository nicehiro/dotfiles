import QtQuick

QtObject {
  readonly property color paper: "#f1e9d2"
  readonly property color ink: "#545464"
  readonly property color inkDeep: "#43436c"
  readonly property color sumi: "#8a8980"
  readonly property color indigo: "#4d699b"
  readonly property color seal: "#c84053"
  readonly property color wash: "#e6dcc0"

  readonly property color bg: Qt.rgba(0.945, 0.914, 0.824, 0.94)
  readonly property color muted: sumi
  readonly property color warn: seal
  readonly property color sep: Qt.rgba(0.33, 0.33, 0.39, 0.18)

  readonly property string serif: "serif"
  readonly property string mono: "IoskeleyMono Nerd Font"

  readonly property var kanjiNum: ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

  function indexKanji(n) {
    return n >= 0 && n <= 10 ? kanjiNum[n] : String(n);
  }
}
