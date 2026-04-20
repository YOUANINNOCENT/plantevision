import tkinter as tk
import cv2
import PIL.Image
import PIL.ImageTk
import os
import threading
import requests
import base64
import io
import json

# Backend configuration: URL du service FastAPI
BACKEND_URL = os.environ.get("BACKEND_URL", "http://127.0.0.1:8000")


def pil_to_base64(pil_img: PIL.Image.Image) -> str:
    """Convertit une image PIL en chaîne base64 JPEG."""
    buffer = io.BytesIO()
    pil_img.save(buffer, format="JPEG", quality=85)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


class AppPlantVision:
    def __init__(self, window):
        self.window = window
        self.window.title("🌿 Identification de Plantes - Plant.id")
        self.window.geometry("1000x800")
        self.window.configure(bg="#1e1e1e")

        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            raise RuntimeError("Impossible d'ouvrir la webcam.")

        self.analyse_en_cours = False

        # --- Interface ---
        self.label_video = tk.Label(window, bg="black")
        self.label_video.pack(pady=10)

        self.btn_scan = tk.Button(
            window,
            text="🌿 IDENTIFIER LA PLANTE",
            command=self.analyser_ia,
            bg="#2e7d32",
            fg="white",
            font=("Arial", 12, "bold"),
            padx=20,
            pady=10,
        )
        self.btn_scan.pack(pady=10)

        self.text_resultat = tk.Text(
            window,
            font=("Arial", 11),
            bg="#2d2d2d",
            fg="#ecf0f1",
            height=10,
            width=80,
            padx=10,
            pady=10,
            state=tk.DISABLED,
        )
        self.text_resultat.pack(pady=10)
        self._set_text("Pointez la caméra vers une plante et cliquez sur le bouton.")

        self.window.protocol("WM_DELETE_WINDOW", self.on_close)
        self.update_frame()

    def _set_text(self, contenu: str):
        self.text_resultat.config(state=tk.NORMAL)
        self.text_resultat.delete(1.0, tk.END)
        self.text_resultat.insert(tk.END, contenu)
        self.text_resultat.config(state=tk.DISABLED)

    def update_frame(self):
        ret, frame = self.cap.read()
        if ret:
            cv2image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = PIL.Image.fromarray(cv2image)
            imgtk = PIL.ImageTk.PhotoImage(image=img)
            self.label_video.imgtk = imgtk
            self.label_video.configure(image=imgtk)
        self.window.after(10, self.update_frame)

    def analyser_ia(self):
        if self.analyse_en_cours:
            return

        ret, frame = self.cap.read()
        if not ret:
            self._set_text("Erreur : impossible de capturer une image.")
            return

        self.analyse_en_cours = True
        self.btn_scan.config(state=tk.DISABLED)
        self._set_text("Identification en cours... 🔍")

        cv2_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        pil_img = PIL.Image.fromarray(cv2_rgb)

        thread = threading.Thread(target=self._appel_api, args=(pil_img,), daemon=True)
        thread.start()

    def _appel_api(self, pil_img: PIL.Image.Image):
        resultat = ""
        try:
            image_b64 = pil_to_base64(pil_img)

            # Envoi vers le backend FastAPI qui se charge d'appeler Plant.id
            url = f"{BACKEND_URL.rstrip('/')}/identify"
            payload = {"images": [image_b64], "user_id": 1}
            resp = requests.post(url, json=payload, timeout=15)
            resp.raise_for_status()
            j = resp.json()
            # backend renvoie le texte formaté dans la clé 'formatted'
            resultat = j.get('formatted') or json.dumps(j.get('raw', j), indent=2)

        except requests.exceptions.HTTPError as e:
            code = e.response.status_code
            if code == 401:
                resultat = (
                    "❌ Clé API invalide (401).\n"
                    "→ Vérifie ta clé sur https://admin.kindwise.com/\n"
                    "→ Copie-la en entier, sans espaces."
                )
            elif code == 429:
                resultat = "⏳ Quota dépassé (429). Réessaie dans quelques secondes."
            else:
                resultat = f"Erreur HTTP {code} :\n{e.response.text}"
        except requests.exceptions.Timeout:
            resultat = "⏱️ Délai dépassé. Vérifie ta connexion internet."
        except Exception as e:
            resultat = f"Erreur inattendue : {e}"
        finally:
            self.window.after(0, self._afficher_resultat, resultat)

    def _formater_resultat(self, data: dict) -> str:
        try:
            result = data.get("result", {})
            classification = result.get("classification", {})
            suggestions = classification.get("suggestions", [])

            if not suggestions:
                is_plant = result.get("is_plant", {}).get("binary", False)
                if not is_plant:
                    return "❌ Aucune plante détectée dans l'image."
                return "⚠️ Plante détectée mais impossible de l'identifier précisément."

            top = suggestions[0]
            nom_sci = top.get("name", "Inconnu")
            proba = round(top.get("probability", 0) * 100, 1)
            details = top.get("details", {})

            noms_communs = details.get("common_names") or []
            nom_commun = ", ".join(noms_communs[:3]) if noms_communs else "Non disponible"

            taxo = details.get("taxonomy", {})
            famille = taxo.get("family", "—")
            genre = taxo.get("genus", "—")

            desc_obj = details.get("description", {})
            description = desc_obj.get("value", "") if isinstance(desc_obj, dict) else ""
            if description and len(description) > 300:
                description = description[:300] + "..."

            def soin(cle):
                obj = details.get(cle, {})
                return obj.get("value", "") if isinstance(obj, dict) else ""

            arrosage = soin("best_watering")
            lumiere = soin("best_light_condition")
            sol = soin("best_soil_type")

            lines = [
                f"🌿 Plante identifiée : {nom_sci} ({proba}% de confiance)",
                f"📛 Noms communs     : {nom_commun}",
                f"🔬 Famille          : {famille} | Genre : {genre}",
            ]
            if description:
                lines += ["", "📖 Description :", description]

            soins = []
            if arrosage:
                soins.append(f"  💧 Arrosage : {arrosage}")
            if lumiere:
                soins.append(f"  ☀️  Lumière  : {lumiere}")
            if sol:
                soins.append(f"  🪴 Sol      : {sol}")
            if soins:
                lines += ["", "🌱 Conseils d'entretien :"] + soins

            if len(suggestions) > 1:
                autres = [
                    f"  - {s['name']} ({round(s['probability']*100,1)}%)"
                    for s in suggestions[1:4]
                ]
                lines += ["", "🔎 Autres possibilités :"] + autres

            return "\n".join(lines)

        except Exception as e:
            return f"Erreur de formatage : {e}\n\nRéponse brute :\n{json.dumps(data, indent=2)}"

    def _afficher_resultat(self, texte: str):
        self._set_text(texte)
        self.analyse_en_cours = False
        self.btn_scan.config(state=tk.NORMAL)

    def on_close(self):
        self.cap.release()
        self.window.destroy()


# --- Lancement ---
if __name__ == "__main__":
    root = tk.Tk()
    app = AppPlantVision(root)
    root.mainloop()
