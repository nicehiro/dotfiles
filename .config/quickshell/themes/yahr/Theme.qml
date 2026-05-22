import QtQuick

QtObject {
  readonly property string themeName: "Eldritch"
  readonly property string uiFont: "Sen"
  readonly property string mono: "IoskeleyMono Nerd Font"
  readonly property string symbols: "Symbols Nerd Font"

  readonly property real barOpacity: 0.74
  readonly property real widgetOpacity: 0.78

  readonly property color accentRose: "#f265b5"
  readonly property color accentCoral: "#f265b5"
  readonly property color accentPink: "#f265b5"
  readonly property color accentPurple: "#a48cf2"
  readonly property color accentRed: "#f16c75"
  readonly property color accentOrange: "#f7c67f"
  readonly property color accentYellow: "#f1fc79"
  readonly property color accentGreen: "#37f499"
  readonly property color accentTeal: "#04d1f9"
  readonly property color accentCyan: "#04d1f9"
  readonly property color accentBlue: "#a48cf2"
  readonly property color accentLavender: "#a48cf2"

  readonly property color fgPrimary: "#ebfafa"
  readonly property color fgSecondary: "#c8d7f0"
  readonly property color fgTertiary: "#7081d0"

  readonly property color border2: "#7081d0"
  readonly property color border1: "#4f5f9f"
  readonly property color border0: "#323449"

  readonly property color surface2: "#3b3d56"
  readonly property color surface1: "#323449"
  readonly property color surface0: "#292b40"

  readonly property color bgBase: "#212337"
  readonly property color bgMantle: "#1b1d2d"
  readonly property color bgCrust: "#151724"

  readonly property color bg: Qt.rgba(bgBase.r, bgBase.g, bgBase.b, barOpacity)
  readonly property color panelBg: Qt.rgba(bgBase.r, bgBase.g, bgBase.b, widgetOpacity)
  readonly property color hoverBg: Qt.rgba(accentBlue.r, accentBlue.g, accentBlue.b, 0.18)
  readonly property color borderGlow: Qt.rgba(accentBlue.r, accentBlue.g, accentBlue.b, 0.35)

  readonly property int fontSizeSmall: 20
  readonly property int fontSizeNormal: 20
  readonly property int fontSizeLarge: 20
  readonly property int fontSizeIcon: 20
}
