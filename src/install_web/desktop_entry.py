import os
import shutil
import stat
import subprocess
from pathlib import Path
from typing import Optional


def install_icon(icon_source: str, app_name: str = "notohiis") -> str:
    icon_path = Path(os.path.expanduser(icon_source))
    if not icon_path.exists():
        raise FileNotFoundError(f"Ícone não encontrado: {icon_path}")

    dest_dir = Path.home() / ".local/share/icons"
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / f"{app_name}.png"
    shutil.copy2(icon_path, dest_path)
    return str(dest_path)


def get_user_desktop_dir() -> Path:
    try:
        result = subprocess.run(
            ["xdg-user-dir", "DESKTOP"],
            capture_output=True,
            text=True,
            check=True,
        )
        path = Path(result.stdout.strip())
        if path.exists():
            return path
    except (FileNotFoundError, subprocess.CalledProcessError):
        pass

    fallback = Path.home() / "Desktop"
    return fallback if fallback.exists() else Path.home()


def _desktop_escape(value: str) -> str:
    return value.replace(" ", "\\ ")


def create_desktop_shortcut(
    app_name: str,
    exec_command: str,
    icon_path: str,
    display_name: Optional[str] = None,
    version: Optional[str] = None,
    create_desktop_file: bool = True,
) -> str:
    app_dir = Path.home() / ".local/share/applications"
    app_dir.mkdir(parents=True, exist_ok=True)

    desktop_file = app_dir / f"{app_name}.desktop"
    content = "[Desktop Entry]\n"
    content += f"Name={display_name or app_name}\n"
    content += "Type=Application\n"
    content += f"Exec={_desktop_escape(exec_command)}\n"
    content += f"Icon={_desktop_escape(os.path.abspath(icon_path))}\n"
    content += "Terminal=false\n"
    content += "Categories=Utility;Development;\n"
    if version:
        content += f"Version={version}\n"
    content += "NoDisplay=false\n"

    desktop_file.write_text(content, encoding="utf-8")
    desktop_file.chmod(desktop_file.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    if create_desktop_file:
        desktop_folder = get_user_desktop_dir()
        if desktop_folder.exists():
            copy_path = desktop_folder / desktop_file.name
            shutil.copy2(desktop_file, copy_path)

    return str(desktop_file)


def remove_icon(app_name: str = "notohiis") -> None:
    icon_path = Path.home() / ".local/share/icons" / f"{app_name}.png"
    if icon_path.exists():
        icon_path.unlink()


def remove_desktop_shortcut(app_name: str = "notohiis") -> None:
    desktop_file = Path.home() / ".local/share/applications" / f"{app_name}.desktop"
    if desktop_file.exists():
        desktop_file.unlink()

    desktop_folder = get_user_desktop_dir()
    desktop_copy = desktop_folder / f"{app_name}.desktop"
    if desktop_copy.exists():
        desktop_copy.unlink()
