#!/usr/bin/env python3
import json
import os
import time
import urllib.request
from datetime import datetime, timezone

CACHE = "/home/pi/bpq-cache/prop.txt"
TMP = CACHE + ".tmp"

URLS = {
    "kp": "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json",
    "kp_forecast": "https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json",
    "solar_wind_mag": "https://services.swpc.noaa.gov/products/solar-wind/mag-1-day.json",
    "solar_wind_plasma": "https://services.swpc.noaa.gov/products/solar-wind/plasma-1-day.json",
}

def fetch_json(url, timeout=12):
    req = urllib.request.Request(url, headers={"User-Agent": "M6VPN-LinBPQ-PROP/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", errors="replace"))

def latest_data_row(rows):
    # SWPC JSON may be either:
    # 1. list of dicts: {"time_tag": "...", "Kp": 2.33}
    # 2. old/table style: [["time_tag", ...], ["2026-...", ...]]
    for row in reversed(rows):
        if isinstance(row, dict):
            return row
        if isinstance(row, list) and row and not str(row[0]).lower().startswith("time"):
            return row
    return None

def safe_float(x):
    try:
        return float(x)
    except Exception:
        return None

def kp_meaning(kp):
    if kp is None:
        return "unknown"
    if kp < 3:
        return "quiet"
    if kp < 5:
        return "unsettled/active"
    if kp < 6:
        return "minor storm"
    if kp < 7:
        return "moderate storm"
    if kp < 8:
        return "strong storm"
    return "severe/extreme storm"

def vhf_note(kp):
    if kp is None:
        return "2m: check locally."
    if kp >= 5:
        return "2m: auroral effects possible; packet may be distorted on auroral paths."
    return "2m: normal local line-of-sight conditions likely."

def hf_note(kp, bz):
    if kp is not None and kp >= 5:
        return "HF: disturbed; expect absorption/fading, especially polar/high-lat paths."
    if bz is not None and bz < -5:
        return "HF: southward Bz; geomagnetic activity may increase."
    return "HF: no major storm flag from Kp/Bz."

def fmt(v, unit="", ndp=1):
    if v is None:
        return "n/a"
    return f"{v:.{ndp}f}{unit}"

def main():
    lines = []
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    kp = None
    kp_time = "n/a"
    forecast = []
    bz = None
    bt = None
    sw_speed = None
    density = None

    try:
        kp_rows = fetch_json(URLS["kp"])
        row = latest_data_row(kp_rows)
        if isinstance(row, dict):
            kp_time = str(row.get("time_tag", "n/a"))
            kp = safe_float(row.get("Kp", row.get("kp")))
        elif isinstance(row, list):
            kp_time = str(row[0])
            kp = safe_float(row[1])
    except Exception as e:
        lines.append(f"Kp fetch error: {e}")

    try:
        fc_rows = fetch_json(URLS["kp_forecast"])
        for row in fc_rows[-6:]:
            if isinstance(row, dict):
                t = row.get("time_tag", "n/a")
                k = row.get("kp", row.get("Kp", "n/a"))
                obs = row.get("observed", "")
                scale = row.get("noaa_scale") or ""
                forecast.append(f"{t} Kp={k} {obs} {scale}".strip())
            elif isinstance(row, list) and len(row) >= 2 and not str(row[0]).lower().startswith("time"):
                forecast.append(" ".join(str(x) for x in row[:4]))
    except Exception as e:
        lines.append(f"Kp forecast fetch error: {e}")

    try:
        mag_rows = fetch_json(URLS["solar_wind_mag"])
        row = latest_data_row(mag_rows)
        if row:
            # usually: time_tag, bx_gsm, by_gsm, bz_gsm, lon_gsm, lat_gsm, bt
            bz = safe_float(row[3]) if len(row) > 3 else None
            bt = safe_float(row[6]) if len(row) > 6 else None
    except Exception as e:
        lines.append(f"Solar wind mag fetch error: {e}")

    try:
        plasma_rows = fetch_json(URLS["solar_wind_plasma"])
        row = latest_data_row(plasma_rows)
        if row:
            # usually: time_tag, density, speed, temperature
            density = safe_float(row[1]) if len(row) > 1 else None
            sw_speed = safe_float(row[2]) if len(row) > 2 else None
    except Exception as e:
        lines.append(f"Solar wind plasma fetch error: {e}")

    out = []
    out.append("M6VPN-7 PROP - cached space weather")
    out.append("-----------------------------------")
    out.append(f"Updated: {now}")
    out.append("")
    out.append(f"Kp:       {fmt(kp, '', 1)}  ({kp_meaning(kp)})")
    out.append(f"Kp time:  {kp_time}")
    out.append(f"Bz:       {fmt(bz, ' nT', 1)}")
    out.append(f"Bt:       {fmt(bt, ' nT', 1)}")
    out.append(f"SW speed: {fmt(sw_speed, ' km/s', 0)}")
    out.append(f"Density:  {fmt(density, ' p/cc', 1)}")
    out.append("")
    out.append(hf_note(kp, bz))
    out.append(vhf_note(kp))
    out.append("")
#    out.append("Packet note:")
#    out.append("  144 MHz packet is mostly line-of-sight.")
#    out.append("  Kp/solar data affects HF more than local 2m FM.")
#    out.append("")

    if forecast:
        out.append("Kp forecast, latest rows:")
        for f in forecast[-3:]:
            out.append("  " + f)
        out.append("")

    if lines:
        out.append("Warnings:")
        for l in lines:
            out.append("  " + l)
        out.append("")

    out.append("Source: NOAA/SWPC cached JSON data.")
    out.append("73 de M6VPN")

    with open(TMP, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    os.replace(TMP, CACHE)

if __name__ == "__main__":
    main()
