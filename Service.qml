import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  // Headless service to manage Antigravity agent integration in Omarchy
  Component.onCompleted: {
    console.log("Antigravity agent plugin loaded")
  }
}
