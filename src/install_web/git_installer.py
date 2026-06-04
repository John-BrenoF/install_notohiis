import os
import subprocess


def download_repository(repo_url: str, target_dir: str) -> str:
    target_dir = os.path.abspath(os.path.expanduser(target_dir))
    if os.path.exists(target_dir) and os.listdir(target_dir):
        raise FileExistsError(f"A pasta de destino já existe e não está vazia: {target_dir}")

    os.makedirs(os.path.dirname(target_dir), exist_ok=True)

    result = subprocess.run(
        ["git", "clone", repo_url, target_dir],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Falha ao clonar o repositório:\n{result.stderr.strip() or result.stdout.strip()}"
        )

    return target_dir
