import sys
import subprocess
import os
from PySide6.QtWidgets import (
    QApplication, QLabel, QLineEdit, QPushButton, QVBoxLayout, 
    QHBoxLayout, QWidget, QListWidget, QListWidgetItem, QFrame, QMessageBox
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont

# --- GLOBAL CONFIGURATION ---
# This will now be controlled by the UI toggle
DEMO_MODE = 1  

VNC_EXE = r"C:\Program Files (x86)\IT Remote Control\vncviewer.exe"
VNC_PORT = 5900
VNC_PASS = "QWErty12"
CRED_PATH = os.path.expanduser(r"~\mysecurecred.xml")

class MainWindow(QWidget):
    def __init__(self, branch_number, computer_list, controller):
        super().__init__()
        self.branch_number = branch_number
        self.computer_list = computer_list
        self.controller = controller 
        self.setWindowTitle(f"VNC-KUPOT - Branch {branch_number} {'(DEMO)' if DEMO_MODE else ''}")
        self.resize(800, 600)
        self.setStyleSheet("background-color: #f5f5f5;")
        
        self.pos_list = QListWidget()
        self.setup_ui()
        self.populate_pos_list()

    def setup_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(20, 20, 20, 20)
        main_layout.setSpacing(15)

        top_bar = QHBoxLayout()
        header = QLabel("POS Selection")
        header.setFont(QFont("Segoe UI", 20, QFont.Bold))
        
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search (Type 0 + Enter to go back)...")
        self.search_input.setFixedWidth(250)
        self.search_input.setFixedHeight(35)
        self.search_input.returnPressed.connect(self.handle_search)

        top_bar.addWidget(header)
        top_bar.addStretch()
        top_bar.addWidget(self.search_input)

        self.btn_connect = self.create_btn("Connect", "#2196F3")
        self.btn_kupa = self.create_btn("Kupa", "#4CAF50")
        self.btn_terminal = self.create_btn("Terminal", "#607D8B")

        self.btn_connect.clicked.connect(lambda: self.run_action("CONNECT_VNC"))
        self.btn_kupa.clicked.connect(lambda: self.run_action("KUPA_PING"))
        self.btn_terminal.clicked.connect(lambda: self.run_action("TERMINAL_PING"))

        top_bar.addWidget(self.btn_connect)
        top_bar.addWidget(self.btn_kupa)
        top_bar.addWidget(self.btn_terminal)
        main_layout.addLayout(top_bar)

        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setStyleSheet("color: #ddd;")
        main_layout.addWidget(line)

        self.pos_list.setFont(QFont("Segoe UI", 12))
        self.pos_list.setStyleSheet("""
            QListWidget { border: 1px solid #ccc; border-radius: 6px; background: #fff; outline: none; }
            QListWidget::item { padding: 12px; border-bottom: 1px solid #eee; }
            QListWidget::item:selected { background-color: #e8f5e9; color: #2e7d32; border-left: 5px solid #4CAF50; }
        """)
        self.pos_list.itemActivated.connect(lambda: self.run_action("CONNECT_VNC"))
        main_layout.addWidget(self.pos_list)

    def create_btn(self, text, color):
        btn = QPushButton(text)
        btn.setFont(QFont("Segoe UI", 10, QFont.Bold))
        btn.setFixedSize(100, 35)
        btn.setCursor(Qt.PointingHandCursor)
        btn.setStyleSheet(f"background-color: {color}; color: white; border-radius: 6px; border: none;")
        return btn

    def populate_pos_list(self):
        self.pos_list.clear()
        self.pos_list.addItems(self.computer_list)
        if self.pos_list.count() > 0:
            self.pos_list.setCurrentRow(0)

    def handle_search(self):
        query = self.search_input.text().strip().lower()
        if query == "0":
            self.controller.go_back_to_login()
            return
        if not query: return
        
        for i in range(self.pos_list.count()):
            item = self.pos_list.item(i)
            if query in item.text().lower():
                self.pos_list.setCurrentItem(item)
                self.pos_list.scrollToItem(item)
                self.pos_list.setFocus()
                return

    def get_target_ip(self, kupa_name, is_terminal):
        try:
            num = kupa_name.split('-')[-1]
            s1 = self.branch_number[0]
            s2 = int(self.branch_number[1:3])
            octet4 = (150 + int(num)) if is_terminal else (10 + int(num))
            return f"10.1{s1}.{s2}.{octet4}"
        except:
            return "0.0.0.0"

    def run_action(self, action_type):
        item = self.pos_list.currentItem()
        if not item: return
        kupa_name = item.text()
        
        if action_type == "TERMINAL_PING":
            ip = self.get_target_ip(kupa_name, True)
            if DEMO_MODE:
                subprocess.Popen(["cmd.exe", "/k", f"echo [DEMO] Pinging TERMINAL {ip} & ping 127.0.0.1 -t"])
            else:
                subprocess.Popen(f'start cmd.exe /k "title PING TERMINAL {kupa_name} && ping -t {ip}"', shell=True)
        
        elif action_type == "KUPA_PING":
            ip = self.get_target_ip(kupa_name, False)
            if DEMO_MODE:
                subprocess.Popen(["cmd.exe", "/k", f"echo [DEMO] Pinging KUPA {ip} & ping 127.0.0.1 -t"])
            else:
                subprocess.Popen(f'start cmd.exe /k "title PING KUPA {kupa_name} && ping -t {ip}"', shell=True)
        
        elif action_type == "CONNECT_VNC":
            ip = self.get_target_ip(kupa_name, False)
            if DEMO_MODE:
                QMessageBox.information(self, "Demo Mode", f"VNC to {ip}")
            else:
                vnc_cmd = f'"{VNC_EXE}" /connect {ip}::{VNC_PORT} /password {VNC_PASS} /scale 1.0'
                subprocess.Popen(f'cmd.exe /c {vnc_cmd}', creationflags=subprocess.CREATE_NO_WINDOW)

# --- LOGIN WINDOW ---
class StartWindow(QWidget):
    def __init__(self, callback):
        super().__init__()
        self.callback = callback
        self.setWindowTitle("VNC-KUPOT Login")
        self.setFixedSize(400, 220)
        self.setup_ui()

    def setup_ui(self):
        layout = QVBoxLayout(self)
        
        # Mode Toggle Button
        self.btn_demo_toggle = QPushButton()
        self.btn_demo_toggle.setFixedHeight(30)
        self.btn_demo_toggle.setCursor(Qt.PointingHandCursor)
        self.btn_demo_toggle.clicked.connect(self.toggle_demo_mode)
        self.update_toggle_style()
        layout.addWidget(self.btn_demo_toggle, alignment=Qt.AlignRight)

        title = QLabel("VNC-KUPOT")
        title.setFont(QFont("Segoe UI", 22, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        self.entry = QLineEdit()
        self.entry.setPlaceholderText("Enter 3-digit Branch")
        self.entry.setFixedHeight(35)
        self.entry.returnPressed.connect(self.submit)
        
        btn_load = QPushButton("Load Branch")
        btn_load.setFixedHeight(40)
        btn_load.clicked.connect(self.submit)
        btn_load.setStyleSheet("background-color: #2196F3; color: white; font-weight: bold; border-radius: 5px;")
        
        layout.addWidget(self.entry)
        layout.addWidget(btn_load)

    def toggle_demo_mode(self):
        global DEMO_MODE
        DEMO_MODE = 0 if DEMO_MODE == 1 else 1
        self.update_toggle_style()

    def update_toggle_style(self):
        if DEMO_MODE:
            self.btn_demo_toggle.setText("Mode: DEMO (ON)")
            self.btn_demo_toggle.setStyleSheet("background-color: #4CAF50; color: white; border-radius: 4px; padding: 5px; font-weight: bold;")
        else:
            self.btn_demo_toggle.setText("Mode: PRODUCTION (OFF)")
            self.btn_demo_toggle.setStyleSheet("background-color: #F44336; color: white; border-radius: 4px; padding: 5px; font-weight: bold;")

    def submit(self):
        branch = self.entry.text().strip()
        if len(branch) == 3 and branch.isdigit():
            if DEMO_MODE:
                comps = [f"pos-{branch}-{i:02d}" for i in range(1, 11)]
            else:
                ps_cmd = f"Import-Module ActiveDirectory; $cred = Import-Clixml '{CRED_PATH}'; Get-ADComputer -Filter 'Name -like \"pos-{branch}-*\"' -Server 'posprod.supersol.co.il' -Credential $cred | Select-Object -ExpandProperty Name"
                res = subprocess.run(["powershell", "-Command", ps_cmd], capture_output=True, text=True)
                comps = [l.strip() for l in res.stdout.split('\n') if l.strip()]
            
            if comps:
                self.callback(branch, comps)
            else:
                QMessageBox.warning(self, "Error", "No computers found.")

class AppController:
    def __init__(self):
        self.start_window = StartWindow(self.show_main)
        self.main_window = None
        self.start_window.show()

    def show_main(self, branch, computers):
        self.start_window.hide()
        self.main_window = MainWindow(branch, computers, self)
        self.main_window.show()

    def go_back_to_login(self):
        if self.main_window:
            self.main_window.close()
        self.start_window.entry.clear()
        self.start_window.show()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    controller = AppController()
    sys.exit(app.exec())