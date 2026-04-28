import os
from typing import Tuple

_SYSTEM_PROMPT = (
    "Tu es un assistant botanique spécialisé. Tu réponds UNIQUEMENT aux questions portant sur "
    "les plantes, la nature, la végétation, les herbes, les fleurs, les arbres, les champignons, "
    "l'horticulture, la botanique, les propriétés médicinales ou culinaires des végétaux, "
    "et les écosystèmes naturels.\n\n"
    "Si la question ne concerne pas ces sujets, réponds poliment : "
    "\"Je suis uniquement spécialisé dans les plantes et la nature. "
    "Je ne peux pas répondre à cette question.\"\n\n"
    "Réponds toujours en français, de façon claire et concise."
)


def get_ai_answer(message: str, system_prompt: str | None = None) -> Tuple[str, int]:
    """Appelle l'API Groq pour générer une réponse botanique."""
    api_key = os.getenv("GROQ_API_KEY", "").strip()

    if not api_key:
        return (
            "Service IA non configuré. Veuillez contacter l'administrateur.",
            0,
        )

    try:
        from groq import Groq
        client = Groq(api_key=api_key)
        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt or _SYSTEM_PROMPT},
                {"role": "user", "content": message},
            ],
            temperature=0.7,
            max_tokens=1024,
        )
        text = completion.choices[0].message.content or ""
        tokens = completion.usage.total_tokens if completion.usage else 0
        return (text, tokens)
    except Exception as e:
        return (f"Erreur IA : {e}", 0)
