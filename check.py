# dq_zero_console.py
# Proyecto Integrador - Avance 1
# Chequeos de calidad de datos 100% heurísticos, TODO por consola, sin esquemas esperados.

import argparse
from pathlib import Path
from datetime import datetime
import json
import re
from typing import Any, Dict, List
import numpy as np
import pandas as pd

# ----------------------- Utils -----------------------

def smart_read_csv(path: Path, nrows: int | None = None) -> pd.DataFrame:
    """Lectura tolerante: infiere delimitador simple y encoding básico.
    - Usa un sniff simple por conteo ; vs ,
    - Fallback a latin1 si falla utf-8,
    - Permite limitar filas para datasets enormes (nrows).
    """
    head = path.read_bytes()[:4096].decode("utf-8", errors="ignore")
    delim = ";" if head.count(";") > head.count(",") else ","
    read_kwargs = {"delimiter": delim}
    if nrows is not None and nrows > 0:
        read_kwargs["nrows"] = nrows
    try:
        return pd.read_csv(path, **read_kwargs)
    except UnicodeDecodeError:
        return pd.read_csv(path, encoding="latin1", **read_kwargs)

def print_header(title: str):
    print("\n" + "="*90)
    print(title)
    print("="*90)

def print_kv(k: str, v):
    print(f"{k:<38}: {v}")

def is_probably_date_col(name: str) -> bool:
    name = name.lower()
    return any(x in name for x in ["date","fecha","day","fech","dt"])

def pct_na_df(df: pd.DataFrame, sample_n: int = 50_000) -> float:
    if len(df) > 250_000:
        s = df.sample(min(sample_n, len(df)), random_state=0)
        return round(s.isna().to_numpy().mean()*100, 2)
    return round(df.isna().to_numpy().mean()*100, 2)

def safe_dup_count(df: pd.DataFrame, subset=None):
    if len(df) > 500_000:
        return "omitido (tabla grande)"
    try:
        return int(df.duplicated(subset=subset).sum())
    except Exception:
        return "error"

def short(series, n=5):
    vals = series.dropna().unique()[:n]
    return ", ".join(map(str, vals))

def mixed_type_ratio(series: pd.Series) -> float:
    """Estima si una columna de texto tiene mezcla número/texto intentando casteo a número.
    Devuelve ratio de filas que NO castearían bien a número (0 a 1)."""
    try:
        if pd.api.types.is_numeric_dtype(series):
            return 0.0
        s = pd.to_numeric(series, errors="coerce")
        # si muchos se convierten a número, probablemente la col deba ser numérica
        # el complemento sugiere mezcla o texto puro
        bad = s.isna() & series.notna()
        return round(float(bad.mean()), 3)
    except Exception:
        return 1.0

# ----------------------- Heuristics -----------------------

def candidate_keys(df: pd.DataFrame, top_k=5):
    """Devuelve columnas que podrían ser keys por alta unicidad."""
    if df.empty: return []
    n = len(df)
    # ratio de unicidad
    ratios = []
    for c in df.columns:
        try:
            u = df[c].nunique(dropna=True)
            ratios.append((c, u/n))
        except Exception:
            pass
    ratios.sort(key=lambda x: x[1], reverse=True)
    # elegimos las que estén cerca de 1.0
    return [(c, round(r,3)) for c, r in ratios[:top_k] if r >= 0.95]

def profile_per_type(df: pd.DataFrame):
    """Checks genéricos por tipo de dato + fecha por nombre/parseo."""
    out = []
    for c in df.columns:
        s = df[c]
        dtype = str(s.dtype)
        na_pct = round(s.isna().mean()*100, 2)
        info = {"col": c, "dtype": dtype, "%NA": na_pct}

        # numéricos
        if pd.api.types.is_numeric_dtype(s):
            try:
                info["min"] = np.nanmin(s.values)
                info["max"] = np.nanmax(s.values)
                info["negatives"] = int((s < 0).sum())
                info["zeros"] = int((s == 0).sum())
            except Exception:
                pass

        # fechas (por nombre o por intento de parseo si tiene pinta)
        if is_probably_date_col(c) or dtype in ("object","string"):
            # intentar parseo conservador
            try:
                parsed = pd.to_datetime(s, errors="coerce", infer_datetime_format=True)
                bad = int(parsed.isna().sum())
                # considerar fecha válida si mejora claramente respecto al %NA
                if bad < 0.9 * len(s):
                    info["as_date_unparsable"] = bad
                    info["as_date_min"] = str(parsed.min())
                    info["as_date_max"] = str(parsed.max())
            except Exception:
                pass

        # texto: % vacíos y mezcla de tipos
        if pd.api.types.is_string_dtype(s) or dtype == "object":
            try:
                blanks = int(s.fillna("").astype(str).str.strip().eq("").sum())
                info["blank_strings"] = blanks
            except Exception:
                pass
            try:
                mix = mixed_type_ratio(s)
                if mix > 0:
                    info["mixed_type_ratio_vs_numeric"] = mix
            except Exception:
                pass

        out.append(info)
    return out

def discover_shared_cols(tables: dict[str, pd.DataFrame]):
    """Encuentra columnas con el mismo nombre presentes en múltiples archivos."""
    col_to_tables = {}
    for tname, df in tables.items():
        for c in df.columns:
            col_to_tables.setdefault(c, set()).add(tname)
    # quedarnos con las que aparecen en 2 o más tablas
    return {c: sorted(list(tset)) for c, tset in col_to_tables.items() if len(tset) >= 2}

def fk_like_check(tables: dict[str, pd.DataFrame], shared: dict[str, list[str]]):
    """Para cada columna compartida, si en una tabla los valores son casi únicos (dim)
    y en otra no, revisa si los valores del 'hijo' ⊆ 'padre'. Reporta huérfanos."""
    findings = []
    for col, tnames in shared.items():
        # armar metrica de unicidad por tabla para la columna
        uniq_ratios = []
        for t in tnames:
            s = tables[t][col]
            u = s.nunique(dropna=True)
            n = len(s)
            uniq_ratios.append((t, u/max(n,1)))
        # ordenar por unicidad descendente (padres arriba)
        uniq_ratios.sort(key=lambda x: x[1], reverse=True)
        # comparar el supuesto padre contra hijos
        for i, (parent_tbl, parent_r) in enumerate(uniq_ratios):
            parent_vals = set(tables[parent_tbl][col].dropna().unique().tolist())
            # si el supuesto “padre” tiene alta unicidad, es candidato a dimensión
            is_parent = parent_r >= 0.5 or col.endswith("_id")
            if not is_parent:
                continue
            for j, (child_tbl, child_r) in enumerate(uniq_ratios):
                if child_tbl == parent_tbl:
                    continue
                child_vals = tables[child_tbl][col]
                missing = (~child_vals.isin(parent_vals)).sum()
                # Solo reportar si hay huérfanos
                if missing > 0:
                    findings.append({
                        "column": col,
                        "parent_table": parent_tbl,
                        "child_table": child_tbl,
                        "parent_unique_ratio": round(parent_r,3),
                        "child_unique_ratio": round(child_r,3),
                        "orphans": int(missing)
                    })
    return findings

# ----------------------- Main -----------------------

def _safe_value_counts(s: pd.Series, topn: int = 5, max_unique_for_counts: int = 2000):
    """Top-N de valores para columnas con cardinalidad manejable."""
    try:
        u = s.nunique(dropna=False)
        if u == 0 or u > max_unique_for_counts:
            return None
        vc = s.value_counts(dropna=False).head(topn)
        # convertir a lista de pares (valor, conteo)
        out = []
        for idx, cnt in vc.items():
            out.append([None if pd.isna(idx) else (str(idx)[:120]), int(cnt)])
        return out
    except Exception:
        return None

def write_markdown_report(md_path: Path, report: Dict[str, Any]):
    """Genera un reporte Markdown con los hallazgos principales."""
    lines: List[str] = []
    lines.append(f"# Reporte de Calidad de Datos — {datetime.now():%Y-%m-%d %H:%M:%S}")
    lines.append("")
    lines.append(f"Directorio analizado: `{report.get('data_dir','')}`  ")
    lines.append(f"Duración: `{report.get('duration','')}`  ")
    lines.append(f"Archivos analizados: `{report.get('files_count',0)}`")
    lines.append("")

    for f in report.get("files", []):
        lines.append(f"## {f['name']}")
        lines.append("")
        lines.append(f"- Filas x Columnas: `{f['rows']} x {f['cols']}`")
        lines.append(f"- %NA (aprox): `{f['pct_na']}%`")
        lines.append(f"- Filas duplicadas: `{f['dup_rows']}`")
        if f.get("candidate_keys"):
            lines.append(f"- Candidate keys: `{f['candidate_keys']}`")
        if f.get("dtypes"):
            lines.append("- Tipos (primeras 10):")
            lines.append("")
            lines.append("| Columna | Dtype |")
            lines.append("|---|---|")
            for col, dt in f["dtypes"]:
                lines.append(f"| {col} | {dt} |")
        if f.get("col_profile"):
            lines.append("")
            lines.append("### Perfil de columnas (primeras 50)")
            lines.append("")
            lines.append("| Col | Dtype | %NA | Min | Max | Neg | Zeros | Blanks | MixedVsNum | FechaMin | FechaMax | NoParseFecha |")
            lines.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---:|")
            for d in f["col_profile"]:
                lines.append(
                    "| {col} | {dtype} | {na} | {min} | {max} | {neg} | {zeros} | {blank} | {mix} | {dmin} | {dmax} | {badd} |".format(
                        col=d.get("col",""), dtype=d.get("dtype",""), na=d.get("%NA",""),
                        min=d.get("min",""), max=d.get("max",""), neg=d.get("negatives",""), zeros=d.get("zeros",""),
                        blank=d.get("blank_strings",""), mix=d.get("mixed_type_ratio_vs_numeric",""),
                        dmin=d.get("as_date_min",""), dmax=d.get("as_date_max",""), badd=d.get("as_date_unparsable", "")
                    )
                )
        if f.get("value_counts"):
            lines.append("")
            lines.append("### Top valores por columna (acotado)")
            for col, pairs in f["value_counts"].items():
                lines.append("")
                lines.append(f"- {col}")
                lines.append("")
                lines.append("| Valor | Conteo |")
                lines.append("|---|---:|")
                for val, cnt in pairs:
                    lines.append(f"| {val} | {cnt} |")

    if report.get("shared_cols"):
        lines.append("")
        lines.append("## Columnas compartidas detectadas")
        for col, tset in report["shared_cols"].items():
            lines.append(f"- `{col}` en: {tset}")

    if report.get("fk_findings"):
        lines.append("")
        lines.append("## Posibles huérfanos (heurística)")
        lines.append("| Columna | Padre | Hijo | uniq(P) | uniq(H) | Huérfanos |")
        lines.append("|---|---|---|---:|---:|---:|")
        for f in report["fk_findings"]:
            lines.append(f"| {f['column']} | {f['parent_table']} | {f['child_table']} | {f['parent_unique_ratio']} | {f['child_unique_ratio']} | {f['orphans']} |")

    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text("\n".join(lines), encoding="utf-8")

def main(data_dir: Path, out_md: Path | None = None, row_limit: int | None = None, top_values: int = 5):
    t0 = datetime.now()
    print_header("Proyecto Integrador — Avance 1 | Chequeos 0-esperado (Consola)")
    print_kv("Data directory", str(data_dir))
    if not data_dir.exists():
        print_kv("ERROR", f"No existe la carpeta: {data_dir}")
        return

    # 1) Descubrir CSVs
    csvs = sorted([p for p in data_dir.glob("*.csv")])
    print_header("1) Archivos CSV detectados")
    if not csvs:
        print("No se encontraron CSV en la carpeta indicada.")
        return
    for p in csvs:
        print(f"- {p.name}")

    # 2) Cargar y perfilar brevemente cada CSV
    print_header("2) Resumen por archivo")
    tables = {}
    report: Dict[str, Any] = {"data_dir": str(data_dir), "files": []}

    for p in csvs:
        try:
            df = smart_read_csv(p, nrows=row_limit)
            tables[p.name] = df
            print(f"\n[{p.name}]")
            print_kv("filas x columnas", f"{len(df)} x {df.shape[1]}")
            print_kv("%NA (aprox)", pct_na_df(df))
            dup = safe_dup_count(df)
            print_kv("filas duplicadas", dup)
            # tipos por columna (muestra)
            dtype_map = {c: str(df[c].dtype) for c in df.columns}
            # recortar para impresión prolija
            sample_cols = list(dtype_map.items())[:10]
            more = "..." if len(dtype_map) > 10 else ""
            print_kv("tipos (primeras 10)", f"{sample_cols} {more}")
            # candidatos a clave
            cks = candidate_keys(df)
            print_kv("candidate keys", cks if cks else "-")

            # recolectar para reporte
            file_entry: Dict[str, Any] = {
                "name": p.name,
                "rows": int(len(df)),
                "cols": int(df.shape[1]),
                "pct_na": pct_na_df(df),
                "dup_rows": dup,
                "dtypes": sample_cols,
                "candidate_keys": cks,
            }
            # perfil columnas (capado a 50)
            details = profile_per_type(df)
            file_entry["col_profile"] = details[:50]
            # top valores por columna (ligero)
            vc_map: Dict[str, Any] = {}
            for c in df.columns[:20]:  # acotar por performance
                vc = _safe_value_counts(df[c], topn=top_values)
                if vc:
                    vc_map[c] = vc
            if vc_map:
                file_entry["value_counts"] = vc_map

            report["files"].append(file_entry)
        except Exception as e:
            print(f"- ERROR leyendo {p.name}: {e}")

    # 3) Checks por tipo (numérico/fecha/texto)
    print_header("3) Chequeos por columna (genéricos)")
    for tname, df in tables.items():
        print(f"\n[{tname}]")
        details = profile_per_type(df)
        # imprimir en forma compacta
        for d in details[:50]:  # límite visual por tabla (ajustable)
            info = {k: d[k] for k in ["col","dtype","%NA"] if k in d}
            # pegar extras si existen
            for k in ["min","max","negatives","zeros","blank_strings","mixed_type_ratio_vs_numeric","as_date_unparsable","as_date_min","as_date_max"]:
                if k in d: info[k] = d[k]
            print(" -", info)
        if len(details) > 50:
            print("   ... (salida truncada, demasiadas columnas)")

    # 4) Heurística de FKs: columnas compartidas
    print_header("4) Heurística de posibles FKs (por columnas compartidas)")
    shared = discover_shared_cols(tables)
    if not shared:
        print("No se detectaron columnas compartidas entre archivos.")
    else:
        # Imprimir columnas compartidas
        for col, tset in sorted(shared.items()):
            print(f"- columna '{col}' en tablas: {tset}")
        # Evaluar orfandad
        findings = fk_like_check(tables, shared)
        if findings:
            print("\nPosibles huérfanos detectados:")
            for f in findings:
                print(f" - col={f['column']} | parent={f['parent_table']} | child={f['child_table']} "
                      f"| parent_unique={f['parent_unique_ratio']} | child_unique={f['child_unique_ratio']} "
                      f"| orphans={f['orphans']}")
        else:
            print("\nNo se detectaron huérfanos en las columnas compartidas analizadas.")

        # para el reporte
        report["shared_cols"] = shared
        report["fk_findings"] = findings if findings else []

    # 5) Resumen final
    print_header("5) Resumen")
    duration = datetime.now() - t0
    print_kv("Archivos analizados", len(tables))
    print_kv("Duración", duration)
    print("\nListo. Usá estos hallazgos para limpiar antes del COPY a Postgres.")

    # completar y persistir reporte si fue solicitado
    report["duration"] = str(duration)
    report["files_count"] = len(report.get("files", []))
    if out_md is not None:
        write_markdown_report(out_md, report)
        print_kv("Reporte MD", str(out_md))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DQ checks sin esquemas esperados (consola)")
    parser.add_argument("--dir", required=True, help="Carpeta con los CSV")
    parser.add_argument("--out-md", dest="out_md", required=False, help="Ruta de salida para reporte Markdown")
    parser.add_argument("--row-limit", dest="row_limit", type=int, required=False, help="Limitar filas leídas por archivo (performance)")
    parser.add_argument("--top-values", dest="top_values", type=int, default=5, help="Top-N de valores en value_counts")
    args = parser.parse_args()
    out_md_path = Path(args.out_md) if args.out_md else None
    main(Path(args.dir), out_md=out_md_path, row_limit=args.row_limit, top_values=args.top_values)
