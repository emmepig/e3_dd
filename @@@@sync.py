import subprocess
import os
from datetime import datetime

def run_git():
    # Ottiene il percorso della cartella dove si trova lo script
    current_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(current_dir)

    print("=== 1. Sincronizzazione in corso (PULL) ===")
    # Assicuriamoci che il ramo si chiami master
    subprocess.run(["git", "branch", "-M", "master"])
    subprocess.run(["git", "pull", "origin", "master"])

    print("\n=== 2. Analisi modifiche ===")
    subprocess.run(["git", "add", "."])

    # Chiede il messaggio all'utente
    now = datetime.now().strftime("%d/%m/%Y %H.%M.%S")
    default_msg = f"aggiornamento rapido {now}"
    
    msg = input(f"Descrizione modifiche (Invio per '{default_msg}'): ").strip()
    if not msg:
        msg = default_msg

    print("\n=== 3. Salvataggio (COMMIT) ===")
    # Usiamo capture_output per gestire il caso "nothing to commit" senza mostrare errori brutti
    result = subprocess.run(["git", "commit", "-m", msg], capture_output=True, text=True)
    
    if "nothing to commit" in result.stdout:
        print("Nessuna modifica rilevata, salto il caricamento.")
    else:
        print(result.stdout)
        print("\n=== 4. Invio al server (PUSH) ===")
        subprocess.run(["git", "push", "origin", "master"])

    print("\n--- Operazione completata! ---")
    input("Premi Invio per chiudere...")

if __name__ == "__main__":
    run_git()