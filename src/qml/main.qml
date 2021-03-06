/*
 * Papyros Terminal - The terminal app for Papyros following Material Design
 * Copyright (C) 2016 Ricardo Vieira <ricardo.vieira@tecnico.ulisboa.pt>
 *               2016 Žiga Patačko Koderman <ziga.patacko@gmail.com>
 *               2016 Michael Spencer <sonrisesoftware@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Window 2.2
import Material 0.2
import Material.Extras 0.1
import Material.ListItems 0.1 as ListItem
import QtQuick.Layouts 1.1
import Papyros.Core 0.2

ApplicationWindow {
    id: mainWindow

    property TerminalTab activeTab: tabbedPage.selectedTab
    property bool __skipConfirmClose

    title: activeTab ? activeTab.title : "Terminal"
    visible: true

    theme {
        primaryColor: Palette.colors.blueGrey["800"]
        primaryDarkColor: Palette.colors.blueGrey["900"]
        tabHighlightColor: "white"
    }

    function pasteClipboard() {
        if (clipboard.text().indexOf("sudo") == 0 && settings.hideSudoWarning != "true") {
            sudoWarningDialog.show()
        } else {
            activeTab.item.terminal.pasteClipboard()
        }
    }

    function addTab() {
        var tab = terminalTabComponent.createObject(tabbedPage.tabs)
        tabbedPage.selectedTabIndex = tabbedPage.tabs.count - 1
    }

    onActiveTabChanged: {
        if (activeTab)
            activeTab.focus()
    }

    onClosing: {
        if (__skipConfirmClose)
            return

        var activeProcesses = []

        for (var i = 0; i < tabbedPage.tabs.count; i++) {
            var tab = tabbedPage.tabs.getTab(i)

            if (tab.item.session.hasActiveProcess) {
                activeProcesses.push(tab.item.session.foregroundProcessName)
            }
        }

        if (activeProcesses.length > 0) {
            close.accepted = false
            confirmCloseDialog.processes = activeProcesses
            confirmCloseDialog.show()
        }
    }

    Component.onCompleted: activeTab.focus()

    Action {
        shortcut: settings.smartCopyPaste == "true" ? StandardKey.Copy : "Ctrl+Shift+C"
        enabled: activeTab.item.terminal.hasSelection || settings.smartCopyPaste == "false"
        onTriggered: activeTab.item.terminal.copyClipboard()
    }

    Action {
        shortcut: settings.smartCopyPaste == "true" ? StandardKey.Paste : "Ctrl+Shift+V"
        onTriggered: pasteClipboard()
    }

    // TODO: Implement search
    // Action {
    //     shortcut: "Ctrl+F"
    //     onTriggered: searchButton.visible = !searchButton.visible
    // }

    Action {
        shortcut: StandardKey.FullScreen

        onTriggered: {
            if (visibility === Window.Windowed) {
                showFullScreen()
            } else {
                showNormal()
            }
        }
    }

    Action {
        shortcut: StandardKey.ZoomIn
        onTriggered: settings.fontSize++
    }

    Action {
        shortcut: StandardKey.ZoomOut
        onTriggered: settings.fontSize--
    }

    initialPage: TabbedPage {
        id: tabbedPage
        title: "Terminal"

        actionBar.tabBar.visible: tabs.count > 1
        actionBar.integratedTabBar: true

        actions: [
            // TODO: Only show when a physical keyboard is not available
            // Action {
            //     iconName: "content/content_paste"
            //     text: qsTr("Paste")
            //     shortcut: StandardKey.Paste
            //     onTriggered: pasteClipboard()
            // },
            Action {
                iconName: "content/add"
                text: qsTr("Open new tab")
                shortcut: StandardKey.AddTab

                onTriggered: addTab()
            },
            Action {
                iconName: "action/open_in_new"
                text: qsTr("Open new window")
                shortcut: "Ctrl+Shift+N"
                onTriggered: {
                    actionHandler.newWindow();
                    console.log("New window")
                }
            },
            Action {
                visible: wallet.enabled
                enabled: wallet.status == KQuickWallet.Open
                iconName: "communication/vpn_key"
                text: qsTr("Passwords")
                onTriggered: passwordsDialog.show()
            },
            // TODO: Implement search
            // Action {
            //     iconName: "action/search"
            //     text: qsTr("Search")
            // },
            Action {
                iconName: "action/settings"
                text: qsTr("Settings")
                onTriggered: settingsDialog.show();
            }
        ]

        Component.onCompleted: addTab()

        Connections {
            target: tabbedPage.tabs
            onCountChanged: {
                if (tabbedPage.tabs.count == 0)
                    Qt.quit()
            }
        }
    }

    Clipboard {
        id: clipboard
    }

    Settings {
        id: settings
        // TODO: This is the way to do it, but the method is not invokable from QML
        // onOpacityChanged: terminal.setOpacity(opacity)
    }

    KQuickWallet {
        id: wallet

        folder: "Terminal Passwords"
    }

    ConfirmCloseDialog {
        id: confirmCloseDialog

        onAccepted: {
            __skipConfirmClose = true
            mainWindow.close()
        }
    }

    PasswordsDialog {
        id: passwordsDialog
    }

    SettingsDialog {
        id: settingsDialog
    }

    SudoWarningDialog {
        id: sudoWarningDialog
    }

    Component {
        id: terminalTabComponent

        TerminalTab {}
    }
}
