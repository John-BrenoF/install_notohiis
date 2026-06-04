import os
import shutil
from pathlib import Path


def remove_directory(path: str) -> None:
    target = Path(os.path.expanduser(path))
    if target.exists() and target.is_dir():
        shutil.rmtree(target)


def remove_icon(app_name: str = "notohiis") -> None:
    icon_path = Path.home() / ".local/share/icons" / f"{app_name}.png"
    if icon_path.exists():
        icon_path.unlink()


def remove_desktop_shortcut(app_name: str = "notohiis") -> None:
    desktop_file = Path.home() / ".local/share/applications" / f"{app_name}.desktop"
    if desktop_file.exists():
        desktop_file.unlink()

    desktop_folder = Path.home() / "Desktop"
    desktop_copy = desktop_folder / f"{app_name}.desktop"
    if desktop_copy.exists():
        desktop_copy.unlink()


def uninstall_notohiis(install_dir: str, app_name: str = "notohiis") -> None:
    target_dir = os.path.abspath(os.path.expanduser(install_dir))
    remove_directory(target_dir)
    remove_icon(app_name)
    remove_desktop_shortcut(app_name)
