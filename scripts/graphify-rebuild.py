from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rebuild the shared Diaverse Graphify graph with a workspace-safe HTML cap override."
    )
    parser.add_argument("--workspace-root", required=True)
    parser.add_argument("--mode", choices=("build", "update"), required=True)
    parser.add_argument("--max-viz-nodes", type=int, default=20000)
    args = parser.parse_args()

    workspace_root = Path(args.workspace_root).resolve()
    out_dir = workspace_root / "graphify-out"
    report_path = out_dir / "GRAPH_REPORT.md"
    graph_path = out_dir / "graph.json"
    html_path = out_dir / "graph.html"
    started_at = time.perf_counter()

    print(f"INFO [graphify] Mode: {args.mode}")
    print(f"DEBUG [graphify] Workspace root resolved to: {workspace_root}")
    print(f"DEBUG [graphify] Output directory: {out_dir}")
    print(f"DEBUG [graphify] HTML node cap override requested: {args.max_viz_nodes}")

    if not workspace_root.exists():
        print(f"ERROR [graphify] Workspace root does not exist: {workspace_root}")
        return 1

    try:
        import graphify.export as graphify_export
        from graphify.watch import _rebuild_code
    except Exception as exc:
        print(f"ERROR [graphify] Failed to import Graphify internals: {exc}")
        return 1

    print(
        "DEBUG [graphify] Graphify MAX_NODES_FOR_VIZ before override: "
        f"{graphify_export.MAX_NODES_FOR_VIZ}"
    )
    graphify_export.MAX_NODES_FOR_VIZ = max(
        args.max_viz_nodes, graphify_export.MAX_NODES_FOR_VIZ
    )
    print(
        "DEBUG [graphify] Graphify MAX_NODES_FOR_VIZ after override: "
        f"{graphify_export.MAX_NODES_FOR_VIZ}"
    )

    ok = _rebuild_code(workspace_root)
    duration_seconds = time.perf_counter() - started_at

    if not ok:
        if report_path.exists() and graph_path.exists():
            print(
                "WARN [graphify] Rebuild returned a soft failure, but the core artifacts "
                "exist. Treating the run as successful."
            )
        else:
            print("ERROR [graphify] Rebuild failed and required artifacts are missing.")
            return 1

    if not report_path.exists():
        print(f"ERROR [graphify] Missing report output: {report_path}")
        return 1

    if not graph_path.exists():
        print(f"ERROR [graphify] Missing graph output: {graph_path}")
        return 1

    if html_path.exists():
        print(f"INFO [graphify] HTML visualization present: {html_path}")
    else:
        print(
            "WARN [graphify] HTML visualization was not produced. "
            f"Core graph artifacts are still ready: {graph_path}"
        )

    print(f"INFO [graphify] Report: {report_path}")
    print(f"INFO [graphify] Graph:  {graph_path}")
    print(f"INFO [graphify] HTML:   {html_path}")
    print(f"INFO [graphify] Duration: {duration_seconds:.2f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
