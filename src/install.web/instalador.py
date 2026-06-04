# baixa um repositorio do github na pasta home do usuario https://github.com/John-BrenoF/notohiis.git somente isso 
import os
import subprocess

# Define o URL do repositório e o caminho de destino
repo_url = "https://github.com/John-BrenoF/notohiis.git"
repo_path = os.path.expanduser("~/notohiis")

# dipara um evento para o src/script/ui/ui.py  que o processo de instalação terminou e que o usuario pode clicar no botao para abrir a pasta do projeto
# para isso vamos criar um arquivo de texto na pasta do projeto com o nome "install_complete.txt" e o conteudo "install_complete" e o src/script/ui/ui.py vai ficar monitorando a pasta do projeto para verificar se esse arquivo existe e se o conteudo é "install_complete
install_complete_file = os.path.join(repo_path, "install_complete.txt")
with open(install_complete_file, "w") as f:
    f.write("install_complete")
print("Instalação concluída! Você pode abrir a pasta do projeto para acessar os arquivos.")
