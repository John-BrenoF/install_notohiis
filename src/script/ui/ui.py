import os
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
from tkinter import ttk

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from install_web.git_installer import download_repository
from install_web.desktop_entry import create_desktop_shortcut, install_icon
from install_web.uninstaller import uninstall_notohiis

REPO_URL = "https://github.com/John-BrenoF/notohiis.git"
APP_NAME = "notohiis"
APP_DISPLAY_NAME = "notohiis 0.4alfa"
APP_VERSION = "0.4alfa"
ICON_PATH = os.path.join(ROOT_DIR, "midia", "icons", "nth.png")

installed_path = None
desktop_file_path = None
open_desktop_button = None
desktop_path_label = None
progress_bar = None
animation_label = None
animation_index = 0
log_text = None
spinner_frames = ["⣷", "⣯", "⣟", "⡿", "⣻", "⣽", "⣾", "⣶"]
animation_running = False


def append_log(message: str, level: str = "INFO"):
    if log_text:
        log_text.configure(state=tk.NORMAL)
        log_text.insert(tk.END, f"[{level}] {message}\n")
        log_text.see(tk.END)
        log_text.configure(state=tk.DISABLED)


def update_animation():
    global animation_index
    if not animation_running or animation_label is None:
        return
    animation_label.config(text=spinner_frames[animation_index % len(spinner_frames)])
    animation_index += 1
    root.after(120, update_animation)


def start_animation():
    global animation_running
    animation_running = True
    if progress_bar:
        progress_bar.start(10)
    update_animation()


def stop_animation():
    global animation_running
    animation_running = False
    if progress_bar:
        progress_bar.stop()
    if animation_label:
        animation_label.config(text="")


def download_and_install(target_dir):
    target_dir = os.path.join(os.path.abspath(target_dir), APP_NAME)
    repo_path = download_repository(REPO_URL, target_dir)
    icon_dest = install_icon(ICON_PATH, APP_NAME)

    shell_path = os.path.join(repo_path, "notohiis.sh")
    if not os.path.exists(shell_path):
        raise FileNotFoundError(f"Arquivo de inicialização não encontrado: {shell_path}")
    os.chmod(shell_path, 0o755)

    desktop_path = create_desktop_shortcut(
        app_name=APP_NAME,
        exec_command=shell_path,
        icon_path=icon_dest,
        display_name=APP_DISPLAY_NAME,
        version=APP_VERSION,
        working_dir=repo_path,
    )
    return repo_path, desktop_path


def perform_uninstall():
    global installed_path, desktop_file_path
    if not installed_path:
        target_dir = os.path.join(selected_path.get(), APP_NAME)
    else:
        target_dir = installed_path

    if not os.path.exists(target_dir):
        messagebox.showwarning("Aviso", "Não existe instalação encontrada para desinstalar.")
        return

    confirm = messagebox.askyesno(
        "Confirmar desinstalação",
        f"Deseja remover a instalação do Notohiis em:\n{target_dir}?",
    )
    if not confirm:
        return

    install_button.config(state=tk.DISABLED)
    select_button.config(state=tk.DISABLED)
    uninstall_button.config(state=tk.DISABLED)
    open_desktop_button.config(state=tk.DISABLED)
    status_label.config(text="Desinstalando... Aguarde.")
    append_log(f"Iniciando desinstalação de: {target_dir}")
    start_animation()

    def worker():
        try:
            uninstall_notohiis(target_dir, APP_NAME)
        except Exception as error:
            root.after(0, lambda: stop_animation())
            root.after(0, lambda: append_log(str(error), level="ERROR"))
            root.after(0, lambda: status_label.config(text="Erro durante a desinstalação."))
            root.after(0, lambda: install_button.config(state=tk.NORMAL))
            root.after(0, lambda: select_button.config(state=tk.NORMAL))
            root.after(0, lambda: messagebox.showerror("Erro", str(error)))
        else:
            def success():
                global installed_path, desktop_file_path
                installed_path = None
                desktop_file_path = None
                uninstall_button.config(state=tk.DISABLED)
                open_desktop_button.config(state=tk.DISABLED)
                desktop_path_label.config(text="")
                install_button.config(state=tk.NORMAL)
                select_button.config(state=tk.NORMAL)
                status_label.config(text="Notohiis desinstalado com sucesso.")
                append_log("Desinstalação concluída com sucesso.")
                stop_animation()
                messagebox.showinfo("Desinstalação", "Notohiis foi removido com sucesso.")

            root.after(0, success)

    threading.Thread(target=worker, daemon=True).start()


def perform_installation():
    selected_folder = selected_path.get()
    if not selected_folder:
        messagebox.showwarning("Aviso", "Escolha uma pasta de instalação primeiro.")
        return

    install_button.config(state=tk.DISABLED)
    select_button.config(state=tk.DISABLED)
    uninstall_button.config(state=tk.DISABLED)
    open_desktop_button.config(state=tk.DISABLED)
    status_label.config(text="Iniciando instalação...")
    append_log("Iniciando instalação do Notohiis.")
    start_animation()

    def worker():
        try:
            root.after(0, lambda: append_log("Clonando repositório Git..."))
            repo_path, desktop_path = download_and_install(selected_folder)
        except Exception as error:
            root.after(0, lambda: stop_animation())
            root.after(0, lambda: append_log(str(error), level="ERROR"))
            root.after(0, lambda: status_label.config(text="Erro durante a instalação."))
            root.after(0, lambda: install_button.config(state=tk.NORMAL))
            root.after(0, lambda: select_button.config(state=tk.NORMAL))
            root.after(0, lambda: messagebox.showerror("Erro", str(error)))
        else:
            def success():
                global installed_path, desktop_file_path
                installed_path = repo_path
                desktop_file_path = desktop_path
                uninstall_button.config(state=tk.NORMAL)
                open_desktop_button.config(state=tk.NORMAL)
                desktop_path_label.config(text=f"Caminho .desktop: {desktop_path}")
                status_label.config(text="Instalação concluída com sucesso.")
                append_log(f"Instalação concluída em: {repo_path}")
                append_log(f"Arquivo .desktop: {desktop_path}")
                stop_animation()
                messagebox.showinfo(
                    "Sucesso",
                    f"Notohiis foi instalado com sucesso!\n\nArquivo .desktop criado em:\n{desktop_path}",
                )

            root.after(0, success)

    threading.Thread(target=worker, daemon=True).start()


def open_desktop_file():
    global desktop_file_path
    if desktop_file_path and os.path.exists(desktop_file_path):
        try:
            os.system(f"xdg-open \"{desktop_file_path}\"")
        except Exception:
            messagebox.showerror("Erro", "Não foi possível abrir o arquivo .desktop.")
    else:
        messagebox.showwarning("Aviso", "Caminho .desktop não disponível.")


def choose_install_folder():
    folder = filedialog.askdirectory(title="Selecione a pasta de instalação")
    if folder:
        selected_path.set(folder)
        install_button.config(state=tk.NORMAL)
        status_label.config(text="Pasta selecionada. Pronto para instalar.")
        append_log(f"Pasta selecionada: {folder}")


def main():
    global root, selected_path, folder_label, install_button, select_button, status_label, uninstall_button, open_desktop_button, desktop_path_label

    root = tk.Tk()
    root.geometry("620x520")
    root.title("Notohiis Installer 0.4alfa")
    root.configure(bg="#11111a")
    root.resizable(False, False)

    style = ttk.Style(root)
    style.theme_use("clam")
    style.configure("TButton", font=("Segoe UI", 10), padding=10)
    style.configure("TLabel", background="#11111a", foreground="#f5f5f5")
    style.configure("Title.TLabel", font=("Segoe UI", 18, "bold"), foreground="#ffffff")
    style.configure("Subtitle.TLabel", font=("Segoe UI", 10), foreground="#bbbbbb")
    style.configure("Log.TLabel", font=("Segoe UI", 9), foreground="#00ccff")
    style.configure("TFrame", background="#11111a")
    style.configure("TEntry", fieldbackground="#1f1f2f", foreground="#ffffff")

    title_frame = ttk.Frame(root, padding=(20, 20, 20, 10))
    title_frame.pack(fill=tk.X)

    title_label = ttk.Label(title_frame, text="Notohiis Installer 0.4alfa", style="Title.TLabel")
    title_label.pack(anchor=tk.W)

    subtitle_label = ttk.Label(title_frame, text="Instale, abra ou desinstale o Notohiis com um clique.", style="Subtitle.TLabel")
    subtitle_label.pack(anchor=tk.W, pady=(4, 0))

    selected_path = tk.StringVar()

    main_frame = ttk.Frame(root, padding=(20, 10, 20, 10))
    main_frame.pack(fill=tk.BOTH, expand=True)

    path_frame = ttk.Frame(main_frame)
    path_frame.pack(fill=tk.X, pady=(0, 12))

    path_label = ttk.Label(path_frame, text="Pasta de instalação:")
    path_label.pack(anchor=tk.W)

    folder_frame = ttk.Frame(path_frame)
    folder_frame.pack(fill=tk.X, pady=(6, 0))

    folder_display = ttk.Entry(folder_frame, textvariable=selected_path, state="readonly", width=50)
    folder_display.pack(side=tk.LEFT, fill=tk.X, expand=True)

    select_button = ttk.Button(folder_frame, text="Selecionar", command=choose_install_folder)
    select_button.pack(side=tk.LEFT, padx=(10, 0))

    desktop_path_label = ttk.Label(main_frame, text="", style="Subtitle.TLabel", wraplength=560, justify=tk.LEFT)
    desktop_path_label.pack(anchor=tk.W, pady=(0, 12))

    button_frame = ttk.Frame(main_frame)
    button_frame.pack(fill=tk.X, pady=(0, 12))

    install_button = ttk.Button(button_frame, text="Instalar Notohiis", command=perform_installation, width=20, state=tk.DISABLED)
    install_button.pack(side=tk.LEFT, padx=(0, 10))

    uninstall_button = ttk.Button(button_frame, text="Desinstalar Notohiis", command=perform_uninstall, width=20, state=tk.DISABLED)
    uninstall_button.pack(side=tk.LEFT, padx=(0, 10))

    open_desktop_button = ttk.Button(button_frame, text="Abrir .desktop", command=open_desktop_file, width=20, state=tk.DISABLED)
    open_desktop_button.pack(side=tk.LEFT)

    progress_bar = ttk.Progressbar(main_frame, mode="indeterminate")
    progress_bar.pack(fill=tk.X, pady=(0, 12))

    animation_label = ttk.Label(main_frame, text="", font=("Segoe UI", 18), foreground="#00ffbf")
    animation_label.pack(anchor=tk.CENTER, pady=(0, 12))

    log_label = ttk.Label(main_frame, text="Logs de instalação:", style="Log.TLabel")
    log_label.pack(anchor=tk.W)

    log_text = scrolledtext.ScrolledText(main_frame, height=10, bg="#0f111a", fg="#e0e0ff", insertbackground="#ffffff", state=tk.DISABLED, wrap=tk.WORD)
    log_text.pack(fill=tk.BOTH, expand=True)

    status_label = ttk.Label(root, text="Selecione a pasta e clique em instalar.", style="Subtitle.TLabel", padding=(20, 10))
    status_label.pack(fill=tk.X)

    root.mainloop()


if __name__ == "__main__":
    main()

