#!/usr/bin/env python3
"""
Bir kerelik içerik scripti: content/ayetler.json içindeki her ayetin Arapça (Uthmani)
orijinal metnini ve global ayet numarasını alquran.cloud API'sinden çekip JSON'a yazar.

Doldurulan alanlar:
  - arapca:    Uthmani Arapça metin (ayet aralığı için ayetler boşlukla birleştirilir)
  - sesAyetNo: global ayet numara(ları) — 1-6236 arası. Çalışma anında hafız ses CDN'i
               (cdn.islamic.network) bu numara ile adreslenir; metin için runtime çağrısı
               GEREKMEZ, Arapça statik olarak buraya yazılır.

Hem `content/ayetler.json` hem de bundle kopyası `Vakit/Resources/Content/ayetler.json`
güncellenir; ikisi senkron kalır.

Kaynak: Al Quran Cloud / Islamic Network API (ücretsiz, anahtar gerektirmez).
Çalıştırma:  python3 scripts/fill_ayet_audio.py
"""
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.alquran.cloud/v1/ayah/{surah}:{ayah}/quran-uthmani"
ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "content" / "ayetler.json"
TARGETS = [SOURCE, ROOT / "Vakit" / "Resources" / "Content" / "ayetler.json"]


def parse_ayah_numbers(ayet_no: str) -> list[int]:
    """'45' -> [45]; '5-6' -> [5, 6]; '7-8' -> [7, 8]."""
    s = str(ayet_no).strip()
    if "-" in s:
        start, end = s.split("-", 1)
        return list(range(int(start), int(end) + 1))
    return [int(s)]


def fetch_ayah(surah: int, ayah: int) -> tuple[str, int]:
    url = API.format(surah=surah, ayah=ayah)
    req = urllib.request.Request(url, headers={"User-Agent": "Vakit-content-fill/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = json.load(resp)
    data = payload["data"]
    return data["text"], int(data["number"])


def main() -> int:
    verses = json.loads(SOURCE.read_text(encoding="utf-8"))
    for verse in verses:
        surah = verse["sureNo"]
        ayahs = parse_ayah_numbers(verse["ayetNo"])
        texts: list[str] = []
        numbers: list[int] = []
        for ayah in ayahs:
            try:
                text, global_no = fetch_ayah(surah, ayah)
            except urllib.error.URLError as err:
                print(f"HATA {verse['id']} {verse['kaynak']} ({surah}:{ayah}): {err}", file=sys.stderr)
                return 1
            texts.append(text)
            numbers.append(global_no)
            time.sleep(0.2)  # API soft rate-limit'ine nazik ol
        verse["arapca"] = " ".join(texts)
        verse["sesAyetNo"] = numbers
        print(f"{verse['id']}  {verse['kaynak']:<22} -> global {numbers}")

    out = json.dumps(verses, ensure_ascii=False, indent=2) + "\n"
    for target in TARGETS:
        target.write_text(out, encoding="utf-8")
    print(f"\nGüncellendi: {len(verses)} ayet -> {', '.join(str(t.relative_to(ROOT)) for t in TARGETS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
