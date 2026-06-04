import os
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox

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

    try:
        uninstall_notohiis(target_dir, APP_NAME)
    except Exception as error:
        messagebox.showerror("Erro", str(error))
        status_label.config(text="Erro durante a desinstalação.")
    else:
        installed_path = None
        desktop_file_path = None
        uninstall_button.config(state=tk.DISABLED)
        open_desktop_button.config(state=tk.DISABLED)
        desktop_path_label.config(text="")
        install_button.config(state=tk.NORMAL)
        select_button.config(state=tk.NORMAL)
        status_label.config(text="Notohiis desinstalado com sucesso.")
        messagebox.showinfo("Desinstalação", "Notohiis foi removido com sucesso.")


def perform_installation():
    selected_folder = selected_path.get()
    if not selected_folder:
        messagebox.showwarning("Aviso", "Escolha uma pasta de instalação primeiro.")
        return

    install_button.config(state=tk.DISABLED)
    select_button.config(state=tk.DISABLED)
    status_label.config(text="Instalando... Aguarde.")

    def worker():
        try:
            repo_path, desktop_path = download_and_install(selected_folder)
        except Exception as error:
            root.after(0, lambda: messagebox.showerror("Erro", str(error)))
            root.after(0, lambda: status_label.config(text="Erro durante a instalação."))
            root.after(0, lambda: install_button.config(state=tk.NORMAL))
            root.after(0, lambda: select_button.config(state=tk.NORMAL))
        else:
            def success():
                global installed_path, desktop_file_path
                installed_path = repo_path
                desktop_file_path = desktop_path
                uninstall_button.config(state=tk.NORMAL)
                open_desktop_button.config(state=tk.NORMAL)
                desktop_path_label.config(text=f"Caminho .desktop: {desktop_path}")
                status_label.config(text=f"Instalação concluída em: {repo_path}")
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
        folder_label.config(text=folder)
        install_button.config(state=tk.NORMAL)
        status_label.config(text="Pasta selecionada. Pronto para instalar.")


def main():
    global root, selected_path, folder_label, install_button, select_button, status_label, uninstall_button, open_desktop_button, desktop_path_label

    root = tk.Tk()
    root.geometry("520x260")
    root.title("Instalador do Notohiis")
    root.resizable(False, False)

    title_label = tk.Label(root, text="Instalador do Notohiis", font=("Helvetica", 16, "bold"))
    title_label.pack(pady=12)

    selected_path = tk.StringVar()

    select_button = tk.Button(root, text="Escolher pasta de instalação", command=choose_install_folder, width=28)
    select_button.pack(pady=8)

    folder_label = tk.Label(root, text="Nenhuma pasta selecionada.", wraplength=480, justify=tk.LEFT)
    folder_label.pack(pady=6)

    install_button = tk.Button(root, text="Instalar Notohiis", command=perform_installation, width=28, state=tk.DISABLED)
    install_button.pack(pady=8)

    uninstall_button = tk.Button(root, text="Desinstalar Notohiis", command=perform_uninstall, width=28, state=tk.DISABLED)
    uninstall_button.pack(pady=8)

    open_desktop_button = tk.Button(root, text="Abrir .desktop", command=open_desktop_file, width=28, state=tk.DISABLED)
    open_desktop_button.pack(pady=8)

    desktop_path_label = tk.Label(root, text="", wraplength=480, justify=tk.LEFT, fg="#007acc")
    desktop_path_label.pack(pady=4)

    status_label = tk.Label(root, text="Selecione a pasta e clique em instalar.")
    status_label.pack(pady=8)

    root.mainloop()


if __name__ == "__main__":
    main()

