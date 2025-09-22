#Made by Thiago Caselato :D
import os
import subprocess

def listar_pasta(caminho="."):
    itens = os.listdir(caminho)
    print(f"\nConteúdo de {caminho}:")
    for i, item in enumerate(itens):
        if os.path.isdir(os.path.join(caminho, item)):
            print(f"{i+1}. [Pasta] {item}")
        else:
            print(f"{i+1}. {item}")
    return itens

def escolher_item(itens, caminho):
    escolha = int(input("Escolha o número: ")) - 1
    item_escolhido = itens[escolha]
    caminho_completo = os.path.join(caminho, item_escolhido)
    
    if os.path.isdir(caminho_completo):
        print(f"Entrando na pasta {item_escolhido}...")
        return explorar_pasta(caminho_completo)
    else:
        return caminho_completo

def explorar_pasta(caminho):
    itens = listar_pasta(caminho)
    return escolher_item(itens, caminho) 

def compilar_c(arquivo):
    output = os.path.splitext(arquivo)[0]
    print(f"Compilando {arquivo}...")
    resultado = subprocess.run(["gcc", arquivo, "-o", output])
    if resultado.returncode == 0:
        print(f"Compilado com sucesso! Executando {output}...")
        subprocess.run([f"./{output}"])
    else:
        print("Erro na compilação.")

def compilar_java(arquivo):
    print(f"Compilando {arquivo}...")
    resultado = subprocess.run(["javac", arquivo])
    if resultado.returncode == 0:
        classe = os.path.splitext(os.path.basename(arquivo))[0]
        print(f"Compilado com sucesso! Executando {classe}...")
        subprocess.run(["java", classe])
    else:
        print("Erro na compilação.")

def compilar_asm(arquivo):
    output = os.path.splitext(arquivo)[0]
    print(f"Compilando {arquivo}...")
    resultado = subprocess.run(["nasm", "-felf64", arquivo, "-o", f"{output}.o"])
    if resultado.returncode == 0:
        print(f"Montado {output}.o, linkando...")
        resultado_link = subprocess.run(["ld", f"{output}.o", "-o", output])
        if resultado_link.returncode == 0:
            print(f"Executando {output}...")
            subprocess.run([f"./{output}"])
        else:
            print("Erro no link do Assembly.")
    else:
        print("Erro na montagem do Assembly.")

def main():
    print("Navegue até o arquivo que deseja compilar:")
    arquivo = explorar_pasta(".")
    
    print("\nEscolha a opção de compilação:")
    print("1. Compilar C")
    print("2. Compilar Java")
    print("3. Compilar Assembly")
    
    opcao = input("Digite a opção: ")
    
    if opcao == "1":
        compilar_c(arquivo)
    elif opcao == "2":
        compilar_java(arquivo)
    elif opcao == "3":
        compilar_asm(arquivo)
    else:
        print("Opção inválida.")

if __name__ == "__main__":
    main()