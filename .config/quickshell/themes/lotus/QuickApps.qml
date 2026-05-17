import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Kanagawa Lotus quick app selector.
// Paper, ink, indigo, vermillion seal. Stillness over motion.
ShellRoot {
    id: root

    property var apps: []
    property int selectedIndex: 0
    readonly property var selectedApp: apps.length ? apps[selectedIndex] : null

    // Kanagawa Lotus palette
    readonly property color paper:   "#f1e9d2"  // cream background
    readonly property color ink:     "#545464"  // lotusInk1
    readonly property color inkDeep: "#43436c"  // lotusInk2
    readonly property color sumi:    "#8a8980"  // lotusGray
    readonly property color indigo:  "#4d699b"  // lotusBlue4
    readonly property color seal:    "#c84053"  // lotusRed
    readonly property color wash:    "#e6dcc0"  // a touch darker than paper, for circle fills
    readonly property string mono: "IoskeleyMono Nerd Font"

    readonly property var kanjiNum: ["〇","一","二","三","四","五","六","七","八","九","十"]
    function indexKanji(n) { return n >= 0 && n <= 10 ? kanjiNum[n] : String(n); }

    function rotate(d) { if (apps.length) selectedIndex = (selectedIndex + d + apps.length) % apps.length; }
    function jumpTo(i)  { if (apps.length) selectedIndex = Math.max(0, Math.min(apps.length - 1, i)); }
    function angleDegFor(i) { return apps.length ? (360 * i) / apps.length - 90 : -90; }

    Process {
        running: true
        command: ["bash", "-c", "cat \"" + Quickshell.shellDir + "/apps.json\" 2>/dev/null || cat \"" + Quickshell.shellDir + "/quickapps.example.json\""]
        stdout: StdioCollector {
            onStreamFinished: { try { root.apps = (JSON.parse(this.text).apps) || []; } catch(e) { console.warn(e); } }
        }
    }

    Process { id: launchProc; running: false; onExited: Qt.quit() }
    function launchSelected() {
        const a = selectedApp; if (!a) return;
        launchProc.command = ["sh","-c","setsid -f " + a.exec + " >/dev/null 2>&1"];
        launchProc.running = true;
    }

    PanelWindow {
        id: panel
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.rgba(0.945, 0.914, 0.824, 0.97)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-lotus-quickapps"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: Qt.quit()
            onWheel: (w) => {
                if (w.angleDelta.y > 0) root.rotate(-1);
                else if (w.angleDelta.y < 0) root.rotate(+1);
                w.accepted = true;
            }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q) { Qt.quit(); e.accepted = true; }
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Up || e.key === Qt.Key_K
                       || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier))) { root.rotate(-1); e.accepted = true; }
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Down || e.key === Qt.Key_J
                       || e.key === Qt.Key_Tab) { root.rotate(+1); e.accepted = true; }
                else if (e.key === Qt.Key_Home) { root.jumpTo(0); e.accepted = true; }
                else if (e.key === Qt.Key_End)  { root.jumpTo(root.apps.length - 1); e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { root.launchSelected(); e.accepted = true; }
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                    const i = e.key - Qt.Key_1;
                    if (i < root.apps.length) { root.selectedIndex = i; root.launchSelected(); }
                    e.accepted = true;
                }
            }
        }

        // Single brush stroke at the top
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 80
            width: 120; height: 1; color: root.ink
        }

        // Background kanji wash
        Text {
            anchors.right: parent.right; anchors.rightMargin: 60
            anchors.verticalCenter: parent.verticalCenter
            text: "静"
            color: Qt.rgba(0.33, 0.33, 0.39, 0.10)
            font.family: "serif"; font.pixelSize: 220; font.weight: Font.Light
        }

        // Position indicator
        Column {
            anchors.right: parent.right; anchors.rightMargin: 60
            anchors.top: parent.top; anchors.topMargin: 80
            spacing: 6
            visible: root.apps.length > 0
            Text {
                anchors.right: parent.right
                text: root.indexKanji(root.selectedIndex + 1)
                color: root.seal
                font.family: "serif"; font.pixelSize: 22; font.weight: Font.Light
            }
            Rectangle { anchors.right: parent.right; width: 1; height: 24; color: root.sumi; opacity: 0.5 }
            Text {
                anchors.right: parent.right
                text: root.indexKanji(root.apps.length)
                color: root.sumi
                font.family: "serif"; font.pixelSize: 20; font.weight: Font.Light
            }
        }

        Item {
            id: stage
            anchors.centerIn: parent
            width: 720; height: 720

            // Faint ring guide, indigo
            Rectangle {
                anchors.centerIn: parent
                width: 460; height: 460; radius: 230
                color: "transparent"
                border.color: Qt.rgba(0.302, 0.412, 0.608, 0.18)
                border.width: 1
            }

            // Center text
            Column {
                anchors.centerIn: parent
                spacing: 18
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.selectedApp ? root.selectedApp.name.toLowerCase() : "—"
                    color: root.ink
                    font.family: "serif"; font.pixelSize: 32; font.letterSpacing: 4; font.weight: Font.Light
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8; height: 8; radius: 4
                    color: root.seal
                    opacity: root.selectedApp ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 600 } }
                    SequentialAnimation on scale {
                        running: root.selectedApp !== null
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.35; duration: 2400; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.35; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.selectedApp ? (root.selectedApp.comment || root.selectedApp.exec || "") : ""
                    color: root.indigo
                    opacity: 0.55
                    font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 2; font.italic: true
                }
            }

            // Circle tiles
            Repeater {
                model: root.apps
                delegate: Item {
                    required property var modelData
                    required property int index
                    readonly property bool focused: index === root.selectedIndex
                    width: 72; height: 96

                    property real angleRad: root.angleDegFor(index) * Math.PI / 180
                    x: stage.width/2  - width/2  + Math.cos(angleRad) * 230
                    y: stage.height/2 - height/2 + Math.sin(angleRad) * 230
                    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

                    // Soft shadow disk under the circle, gives lift on the cream paper
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: disk.verticalCenter
                        anchors.verticalCenterOffset: 2
                        width: 58; height: 58; radius: 29
                        color: Qt.rgba(0.302, 0.412, 0.608, 0.07)  // indigo, very faint
                        visible: !parent.focused
                    }

                    Rectangle {
                        id: disk
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 56; height: 56; radius: 28
                        color: parent.focused ? root.ink : root.wash
                        border.color: parent.focused ? root.ink : Qt.rgba(0.302, 0.412, 0.608, 0.35)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 350 } }
                        Behavior on border.color { ColorAnimation { duration: 350 } }
                    }

                    // Subtle index numeral for number-key affordance
                    Text {
                        anchors.right: disk.right; anchors.rightMargin: -2
                        anchors.top: disk.top; anchors.topMargin: -2
                        visible: parent.index < 9
                        text: String(parent.index + 1)
                        color: parent.focused ? root.seal : root.sumi
                        opacity: parent.focused ? 0.9 : 0.45
                        font.family: "serif"; font.pixelSize: 20; font.weight: Font.Light
                    }

                    // Icon, tinted to follow the theme. Source is hidden; the
                    // MultiEffect renders a fully colorized copy.
                    Image {
                        id: iconImg
                        anchors.centerIn: disk
                        width: 28; height: 28
                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                        smooth: true; asynchronous: true; fillMode: Image.PreserveAspectFit
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: iconImg
                        source: iconImg
                        visible: iconImg.status === Image.Ready
                        colorization: 1.0
                        colorizationColor: parent.focused ? root.paper : root.ink
                        opacity: parent.focused ? 0.95 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    // Fallback glyph if no icon resolved
                    Text {
                        anchors.centerIn: disk
                        visible: iconImg.status !== Image.Ready
                        text: (modelData.name || "?").charAt(0).toLowerCase()
                        color: parent.focused ? root.paper : root.ink
                        font.family: "serif"; font.pixelSize: 22; font.weight: Font.Light
                        Behavior on color { ColorAnimation { duration: 350 } }
                    }

                    // Tiny red dot only on focused
                    Rectangle {
                        anchors.horizontalCenter: disk.horizontalCenter
                        anchors.top: disk.bottom; anchors.topMargin: 8
                        width: 4; height: 4; radius: 2
                        color: root.seal
                        opacity: parent.focused ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 350 } }
                    }
                    Text {
                        anchors.horizontalCenter: disk.horizontalCenter
                        anchors.top: disk.bottom; anchors.topMargin: 18
                        text: (modelData.name || "").toLowerCase()
                        color: parent.focused ? root.ink : root.sumi
                        font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 1.5
                        opacity: parent.focused ? 1 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    scale: focused ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = parent.index
                        onClicked: { root.selectedIndex = parent.index; root.launchSelected(); }
                    }
                }
            }
        }

        // Hint footer
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 60
            spacing: 18

            Text {
                text: "← →"
                color: root.sumi
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 3
            }
            Text {
                text: "navigate"
                color: root.sumi; opacity: 0.7
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 2; font.italic: true
            }
            Rectangle { width: 1; height: 12; color: root.sumi; opacity: 0.4; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "↵"
                color: root.seal
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 3
            }
            Text {
                text: "open"
                color: root.sumi; opacity: 0.7
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 2; font.italic: true
            }
            Rectangle { width: 1; height: 12; color: root.sumi; opacity: 0.4; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "esc"
                color: root.sumi
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 3
            }
            Text {
                text: "dismiss"
                color: root.sumi; opacity: 0.7
                font.family: "serif"; font.pixelSize: 20; font.letterSpacing: 2; font.italic: true
            }
        }
    }
}
