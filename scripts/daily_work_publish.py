"""Local Daily Work document helper and Confluence publisher.

The script is intentionally self-contained and uses only the Python standard
library so it can run from the workspace without installing service deps.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import html
import json
import logging
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


LOGGER = logging.getLogger("daily_work")
SECTION_PATTERN = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
DEFAULT_LABEL = "diaverse-daily-work"
DEFAULT_AUTHOR = "safiu"
AUTHOR_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
MAX_PUBLIC_CHARS = 40000
LOCAL_ENV_FILE = ".env.daily-work"

UNSAFE_PUBLIC_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("ssh_command", re.compile(r"\bssh\s+", re.IGNORECASE)),
    (
        "secret_marker",
        re.compile(
            r"\b(api[_-]?key|api[_-]?token|token|secret|password|passwd|private[_-]?key)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "env_assignment",
        re.compile(r"\b[A-Z][A-Z0-9_]{2,}\s*=\s*\S+"),
    ),
    (
        "ip_address",
        re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b"),
    ),
)


@dataclass(frozen=True)
class DailyWorkConfig:
    base_url: str
    email: str
    api_token: str
    space_id: str
    parent_page_id: str
    label_name: str
    timeout_seconds: float

    @property
    def configured(self) -> bool:
        return bool(
            self.base_url
            and self.email
            and self.api_token
            and (self.parent_page_id or self.space_id)
        )


@dataclass(frozen=True)
class SectionCounts:
    public_chars: int
    internal_chars: int
    unsafe_public_markers: tuple[str, ...]


class DailyWorkError(RuntimeError):
    """Raised for expected script failures that should be shown safely."""


class ConfluenceHTTPError(DailyWorkError):
    """Raised for expected Confluence HTTP errors with a status code."""

    def __init__(self, message: str, status_code: int) -> None:
        super().__init__(message)
        self.status_code = status_code


def configure_logging() -> None:
    level_name = (
        os.getenv("DAILY_WORK_LOG_LEVEL")
        or os.getenv("LOG_LEVEL")
        or "INFO"
    ).upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(levelname)s [daily-work] %(message)s",
    )


def workspace_root() -> Path:
    return Path(__file__).resolve().parents[1]


def load_local_env_file() -> None:
    env_path = workspace_root() / LOCAL_ENV_FILE
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export ") :].lstrip()
        key, value = line.split("=", 1)
        key = key.strip()
        if not key:
            continue
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def resolve_author(value: str = "") -> str:
    author = (
        value
        or env_value("DAILY_WORK_AUTHOR", "COPYWRITING_DAILY_WORK_AUTHOR", DEFAULT_AUTHOR)
    ).strip()
    if not AUTHOR_PATTERN.fullmatch(author):
        raise DailyWorkError(
            "Daily Work author must be an ASCII slug: letters, numbers, dot, underscore, or dash"
        )
    return author


def default_daily_path(date_value: str, author: str | None = None) -> Path:
    author_slug = author or resolve_author()
    return workspace_root() / "docs" / "daily" / f"{date_value}-{author_slug}.md"


def today_string() -> str:
    return dt.date.today().isoformat()


def read_template(date_value: str, author: str) -> str:
    template_path = workspace_root() / "docs" / "daily" / "TEMPLATE.md"
    if template_path.exists():
        template = template_path.read_text(encoding="utf-8")
    else:
        template = (
            "# Daily Work - {{date}} [{{author}}]\n\n"
            "## Public digest\n\n"
            "<!-- Только безопасные публичные заметки на русском. Этот раздел можно публиковать в Confluence. -->\n\n"
            "## Internal log\n"
            "<!-- Только локальные технические заметки на русском. Этот раздел нельзя публиковать или отправлять в генерацию постов. -->\n"
        )
    return (
        template.replace("{{date}}", date_value)
        .replace("{{author}}", author)
        .replace("[safiu]", f"[{author}]")
        .rstrip()
        + "\n"
    )


def ensure_daily_file(path: Path, date_value: str, author: str) -> None:
    if path.exists():
        text = path.read_text(encoding="utf-8")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        text = read_template(date_value, author)
        path.write_text(text, encoding="utf-8")
        LOGGER.info("add.created_file path=%s date=%s", path, date_value)
        return

    changed = False
    if "## Public digest" not in text:
        text = text.rstrip() + "\n\n## Public digest\n"
        changed = True
    if "## Internal log" not in text:
        text = text.rstrip() + "\n\n## Internal log\n"
        changed = True
    if changed:
        path.write_text(text.rstrip() + "\n", encoding="utf-8")
        LOGGER.info("add.normalized_file path=%s date=%s", path, date_value)


def section_bounds(text: str, section_name: str) -> tuple[int, int] | None:
    matches = list(SECTION_PATTERN.finditer(text))
    target = section_name.strip().lower()
    for index, match in enumerate(matches):
        current = match.group(1).strip().lower()
        if current != target:
            continue
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        LOGGER.debug(
            "section.bounds section=%s start=%s end=%s",
            section_name,
            start,
            end,
        )
        return start, end
    LOGGER.debug("section.missing section=%s", section_name)
    return None


def extract_section(text: str, section_name: str) -> str:
    bounds = section_bounds(text, section_name)
    if bounds is None:
        return ""
    start, end = bounds
    return text[start:end].strip()


def format_bullet_entry(value: str) -> str:
    lines = [line.strip() for line in value.splitlines() if line.strip()]
    if not lines:
        return ""
    first, *rest = lines
    bullet_lines = [f"- {first}"]
    bullet_lines.extend(f"  {line}" for line in rest)
    return "\n".join(bullet_lines)


def append_to_section(text: str, section_name: str, entry: str) -> str:
    bullet = format_bullet_entry(entry)
    if not bullet:
        return text

    bounds = section_bounds(text, section_name)
    if bounds is None:
        text = text.rstrip() + f"\n\n## {section_name}\n"
        bounds = section_bounds(text, section_name)
    if bounds is None:
        raise DailyWorkError(f"Could not find or create section: {section_name}")

    start, end = bounds
    before = text[:start]
    section_body = text[start:end].strip()
    after = text[end:]
    new_body = f"\n\n{section_body}\n\n{bullet}" if section_body else f"\n\n{bullet}"
    return before + new_body.rstrip() + "\n\n" + after.lstrip("\n")


def detect_unsafe_public_markers(public_text: str) -> tuple[str, ...]:
    markers = [
        marker
        for marker, pattern in UNSAFE_PUBLIC_PATTERNS
        if pattern.search(public_text)
    ]
    return tuple(sorted(set(markers)))


def count_sections(path: Path) -> SectionCounts:
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    public_text = extract_section(text, "Public digest")
    internal_text = extract_section(text, "Internal log")
    return SectionCounts(
        public_chars=len(public_text),
        internal_chars=len(internal_text),
        unsafe_public_markers=detect_unsafe_public_markers(public_text),
    )


def add_entry(args: argparse.Namespace) -> int:
    date_value = args.date or today_string()
    author = resolve_author(args.author)
    path = default_daily_path(date_value, author)
    LOGGER.info("add.start date=%s author=%s path=%s", date_value, author, path)
    ensure_daily_file(path, date_value, author)

    if args.skip_empty and not args.public and not args.internal:
        LOGGER.info("add.skip_empty date=%s path=%s", date_value, path)
        return 0

    text = path.read_text(encoding="utf-8")
    if args.public:
        text = append_to_section(text, "Public digest", args.public)
    if args.internal:
        text = append_to_section(text, "Internal log", args.internal)
    path.write_text(text.rstrip() + "\n", encoding="utf-8")

    counts = count_sections(path)
    if counts.unsafe_public_markers:
        LOGGER.warning(
            "add.unsafe_public_markers markers=%s",
            ",".join(counts.unsafe_public_markers),
        )
    LOGGER.info(
        "add.done date=%s author=%s path=%s public_chars=%s internal_chars=%s",
        date_value,
        author,
        path,
        counts.public_chars,
        counts.internal_chars,
    )
    return 0


def env_value(primary: str, fallback: str | None = None, default: str = "") -> str:
    value = os.getenv(primary, "").strip()
    if value:
        return value
    if fallback:
        fallback_value = os.getenv(fallback, "").strip()
        if fallback_value:
            return fallback_value
    return default


def load_config() -> DailyWorkConfig:
    timeout_raw = env_value(
        "DAILY_WORK_CONFLUENCE_TIMEOUT_SECONDS",
        "COPYWRITING_CONFLUENCE_TIMEOUT_SECONDS",
        "15",
    )
    try:
        timeout_seconds = float(timeout_raw)
    except ValueError:
        timeout_seconds = 15.0

    return DailyWorkConfig(
        base_url=env_value("DAILY_WORK_CONFLUENCE_BASE_URL", "COPYWRITING_CONFLUENCE_BASE_URL"),
        email=env_value("DAILY_WORK_CONFLUENCE_EMAIL", "COPYWRITING_CONFLUENCE_EMAIL"),
        api_token=env_value(
            "DAILY_WORK_CONFLUENCE_API_TOKEN",
            "COPYWRITING_CONFLUENCE_API_TOKEN",
        ),
        space_id=env_value("DAILY_WORK_CONFLUENCE_SPACE_ID", "COPYWRITING_CONFLUENCE_SPACE_ID"),
        parent_page_id=env_value(
            "DAILY_WORK_CONFLUENCE_PARENT_PAGE_ID",
            "COPYWRITING_CONFLUENCE_PARENT_PAGE_ID",
        ),
        label_name=env_value(
            "DAILY_WORK_CONFLUENCE_LABEL_NAME",
            "COPYWRITING_CONFLUENCE_LABEL_NAME",
            DEFAULT_LABEL,
        ),
        timeout_seconds=timeout_seconds if timeout_seconds > 0 else 15.0,
    )


def missing_config_keys(config: DailyWorkConfig) -> list[str]:
    missing: list[str] = []
    if not config.base_url:
        missing.append("DAILY_WORK_CONFLUENCE_BASE_URL")
    if not config.email:
        missing.append("DAILY_WORK_CONFLUENCE_EMAIL")
    if not config.api_token:
        missing.append("DAILY_WORK_CONFLUENCE_API_TOKEN")
    if not config.parent_page_id and not config.space_id:
        missing.append("DAILY_WORK_CONFLUENCE_PARENT_PAGE_ID or DAILY_WORK_CONFLUENCE_SPACE_ID")
    return missing


def status(args: argparse.Namespace) -> int:
    date_value = args.date or today_string()
    author = resolve_author(args.author)
    path = Path(args.file).resolve() if args.file else default_daily_path(date_value, author)
    config = load_config()
    counts = count_sections(path) if path.exists() else SectionCounts(0, 0, ())
    missing = missing_config_keys(config)

    LOGGER.info(
        "status.done date=%s author=%s path=%s exists=%s public_chars=%s internal_chars=%s configured=%s",
        date_value,
        author,
        path,
        path.exists(),
        counts.public_chars,
        counts.internal_chars,
        not missing,
    )
    if counts.unsafe_public_markers:
        LOGGER.warning(
            "status.unsafe_public_markers markers=%s",
            ",".join(counts.unsafe_public_markers),
        )
    if missing:
        LOGGER.warning("status.missing_config keys=%s", ",".join(missing))

    print(
        json.dumps(
            {
                "date": date_value,
                "author": author,
                "path": str(path),
                "target_title": confluence_page_title(date_value),
                "exists": path.exists(),
                "public_chars": counts.public_chars,
                "internal_chars": counts.internal_chars,
                "unsafe_public_markers": list(counts.unsafe_public_markers),
                "confluence_configured": not missing,
                "missing_config_keys": missing,
                "label_name_configured": bool(config.label_name),
                "parent_page_configured": bool(config.parent_page_id),
                "space_configured": bool(config.space_id),
            },
            ensure_ascii=True,
            indent=2,
        )
    )
    return 0


def normalize_base_url(base_url: str) -> str:
    normalized = base_url.strip().rstrip("/")
    if normalized.endswith("/wiki"):
        normalized = normalized[:-5]
    return normalized


def api_url(config: DailyWorkConfig, path: str) -> str:
    site = normalize_base_url(config.base_url)
    return f"{site}/wiki/api/v2/{path.lstrip('/')}"


def web_url(config: DailyWorkConfig, webui: str | None, page_id: str) -> str:
    site = normalize_base_url(config.base_url)
    if webui:
        if webui.startswith("http://") or webui.startswith("https://"):
            return webui
        return urllib.parse.urljoin(f"{site}/", webui.lstrip("/"))
    return f"{site}/wiki/spaces/{config.space_id}/pages/{page_id}"


def request_json(
    config: DailyWorkConfig,
    method: str,
    path: str,
    *,
    params: dict[str, Any] | None = None,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    url = api_url(config, path)
    if params:
        query = urllib.parse.urlencode({key: value for key, value in params.items() if value != ""})
        url = f"{url}?{query}"
    safe_url = re.sub(r"([?&][^=]+)=([^&]+)", r"\1=<set>", url)
    LOGGER.debug("confluence.request method=%s url=%s", method, safe_url)

    body_bytes = None
    if payload is not None:
        body_bytes = json.dumps(payload).encode("utf-8")

    token = base64.b64encode(f"{config.email}:{config.api_token}".encode("utf-8")).decode("ascii")
    request = urllib.request.Request(
        url,
        data=body_bytes,
        method=method,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"Basic {token}",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=config.timeout_seconds) as response:
            raw_body = response.read()
            if not raw_body:
                return {}
            decoded = raw_body.decode("utf-8")
            parsed = json.loads(decoded)
            return parsed if isinstance(parsed, dict) else {}
    except urllib.error.HTTPError as exc:
        reason = exc.reason or "HTTP error"
        LOGGER.error(
            "confluence.http_error method=%s path=%s status=%s reason=%s",
            method,
            path,
            exc.code,
            reason,
        )
        raise ConfluenceHTTPError(
            f"Confluence request failed: status={exc.code} reason={reason}",
            exc.code,
        ) from exc
    except urllib.error.URLError as exc:
        LOGGER.error(
            "confluence.transport_error method=%s path=%s reason=%s",
            method,
            path,
            exc.reason,
        )
        raise DailyWorkError("Confluence transport error") from exc
    except TimeoutError as exc:
        LOGGER.error("confluence.timeout method=%s path=%s", method, path)
        raise DailyWorkError("Confluence request timed out") from exc


def markdown_lines_to_storage(public_text: str) -> str:
    lines = [line.rstrip() for line in public_text.splitlines()]
    parts: list[str] = []
    in_list = False
    paragraph: list[str] = []

    def flush_paragraph() -> None:
        nonlocal paragraph
        if paragraph:
            parts.append(f"<p>{html.escape(' '.join(paragraph))}</p>")
            paragraph = []

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            parts.append("</ul>")
            in_list = False

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("<!--"):
            flush_paragraph()
            close_list()
            continue
        if stripped.startswith("- "):
            flush_paragraph()
            if not in_list:
                parts.append("<ul>")
                in_list = True
            parts.append(f"<li>{html.escape(stripped[2:].strip())}</li>")
            continue
        close_list()
        paragraph.append(stripped)
    flush_paragraph()
    close_list()
    return "".join(parts)


def author_block_marker(author: str, position: str) -> str:
    return f"<!-- daily-work:author:{author}:{position} -->"


def markdown_public_to_author_storage(public_text: str, author: str) -> str:
    return "".join(
        [
            author_block_marker(author, "start"),
            f"<h2>{html.escape(author)}</h2>",
            markdown_lines_to_storage(public_text),
            author_block_marker(author, "end"),
        ]
    )


def shared_page_skeleton(date_value: str) -> str:
    return f"<h1>Daily Work - {html.escape(date_value)}</h1>"


def replace_unmarked_author_storage(
    base_storage: str,
    author_block: str,
    author: str,
) -> tuple[str, bool]:
    heading_pattern = re.compile(
        rf"<h2\b[^>]*>\s*{re.escape(html.escape(author))}\s*</h2>",
        re.IGNORECASE,
    )
    matches = list(heading_pattern.finditer(base_storage))
    if not matches:
        return base_storage, False

    spans: list[tuple[int, int]] = []
    next_heading_pattern = re.compile(r"<h2\b[^>]*>", re.IGNORECASE)
    for match in matches:
        next_heading = next_heading_pattern.search(base_storage, match.end())
        end = next_heading.start() if next_heading else len(base_storage)
        spans.append((match.start(), end))

    parts: list[str] = []
    cursor = 0
    inserted = False
    for start, end in spans:
        parts.append(base_storage[cursor:start])
        if not inserted:
            parts.append(author_block)
            inserted = True
        cursor = end
    parts.append(base_storage[cursor:])
    return "".join(parts), True


def merge_author_storage(
    existing_storage: str,
    public_text: str,
    date_value: str,
    author: str,
) -> str:
    base_storage = existing_storage.strip() or shared_page_skeleton(date_value)
    author_block = markdown_public_to_author_storage(public_text, author)
    pattern = re.compile(
        rf"<!--\s*daily-work:author:{re.escape(author)}:start\s*-->.*?"
        rf"<!--\s*daily-work:author:{re.escape(author)}:end\s*-->",
        re.DOTALL,
    )
    if pattern.search(base_storage):
        return pattern.sub(author_block, base_storage)
    unmarked_storage, replaced = replace_unmarked_author_storage(
        base_storage,
        author_block,
        author,
    )
    if replaced:
        return unmarked_storage
    return base_storage.rstrip() + author_block


def markdown_public_to_storage(public_text: str, date_value: str, author: str) -> str:
    return merge_author_storage("", public_text, date_value, author)


def confluence_page_title(date_value: str) -> str:
    return f"Daily Work - {date_value}"


def find_existing_page(config: DailyWorkConfig, title: str) -> dict[str, Any] | None:
    if config.parent_page_id:
        payload = request_json(
            config,
            "GET",
            f"/pages/{config.parent_page_id}/direct-children",
            params={"limit": 250, "sort": "-modified-date"},
        )
    else:
        payload = request_json(
            config,
            "GET",
            "/pages",
            params={"space-id": config.space_id, "limit": 250, "sort": "-modified-date"},
        )
    for item in payload.get("results", []):
        if not isinstance(item, dict):
            continue
        if str(item.get("title") or "").strip() == title:
            return item
    return None


def page_detail(config: DailyWorkConfig, page_id: str, *, include_body: bool = False) -> dict[str, Any]:
    params = {"body-format": "storage"} if include_body else None
    return request_json(config, "GET", f"/pages/{page_id}", params=params)


def storage_body_from_page(detail: dict[str, Any]) -> str:
    body = detail.get("body")
    if not isinstance(body, dict):
        return ""
    storage = body.get("storage")
    if isinstance(storage, dict):
        return str(storage.get("value") or "")
    return str(body.get("value") or "")


def create_page(config: DailyWorkConfig, title: str, storage_html: str) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "spaceId": config.space_id,
        "status": "current",
        "title": title,
        "body": {
            "representation": "storage",
            "value": storage_html,
        },
    }
    if config.parent_page_id:
        payload["parentId"] = config.parent_page_id
    return request_json(config, "POST", "/pages", payload=payload)


def update_page(
    config: DailyWorkConfig,
    page_id: str,
    title: str,
    version_number: int,
    storage_html: str,
) -> dict[str, Any]:
    payload = {
        "id": page_id,
        "status": "current",
        "title": title,
        "body": {
            "representation": "storage",
            "value": storage_html,
        },
        "version": {
            "number": version_number + 1,
            "message": "Update Daily Work public digest",
        },
    }
    return request_json(config, "PUT", f"/pages/{page_id}", payload=payload)


def add_label(config: DailyWorkConfig, page_id: str) -> None:
    label_name = config.label_name.strip()
    if not label_name:
        return
    LOGGER.info("confluence.label_skipped page_id=%s label_configured=%s", page_id, True)


def publish(args: argparse.Namespace) -> int:
    date_value = args.date or today_string()
    author = resolve_author(args.author)
    path = Path(args.file).resolve() if args.file else default_daily_path(date_value, author)
    LOGGER.info("publish.start date=%s author=%s path=%s", date_value, author, path)
    if not path.exists():
        raise DailyWorkError(f"Daily work file does not exist: {path}")

    text = path.read_text(encoding="utf-8")
    public_text = extract_section(text, "Public digest")
    internal_text = extract_section(text, "Internal log")
    unsafe_markers = detect_unsafe_public_markers(public_text)
    LOGGER.info(
        "publish.sections public_chars=%s internal_chars=%s",
        len(public_text),
        len(internal_text),
    )
    if not public_text.strip():
        LOGGER.warning("publish.empty_public_digest path=%s", path)
        raise DailyWorkError("Public digest is empty; nothing safe to publish")
    if len(public_text) > MAX_PUBLIC_CHARS:
        raise DailyWorkError(f"Public digest is too large: {len(public_text)} chars")
    if unsafe_markers and not args.allow_unsafe_public_digest:
        LOGGER.warning("publish.unsafe_public_markers markers=%s", ",".join(unsafe_markers))
        raise DailyWorkError("Public digest contains unsafe markers; refusing to publish")

    config = load_config()
    missing = missing_config_keys(config)
    if missing:
        LOGGER.warning("publish.missing_config keys=%s", ",".join(missing))
        if not args.dry_run:
            raise DailyWorkError("Confluence config is incomplete")

    title = confluence_page_title(date_value)
    LOGGER.info(
        "publish.target title=%s author=%s dry_run=%s label_configured=%s parent_configured=%s",
        title,
        author,
        args.dry_run,
        bool(config.label_name),
        bool(config.parent_page_id),
    )
    if args.dry_run:
        print(
            json.dumps(
                {
                    "dry_run": True,
                    "date": date_value,
                    "author": author,
                    "path": str(path),
                    "title": title,
                    "public_chars": len(public_text),
                    "unsafe_public_markers": list(unsafe_markers),
                    "confluence_configured": not missing,
                    "missing_config_keys": missing,
                },
                ensure_ascii=True,
                indent=2,
            )
        )
        return 0

    existing = find_existing_page(config, title)
    if existing:
        page_id = str(existing.get("id") or "").strip()
        for attempt in range(1, 4):
            detail = page_detail(config, page_id, include_body=True)
            version = detail.get("version") if isinstance(detail.get("version"), dict) else {}
            version_number = int(version.get("number") or 1)
            storage_html = merge_author_storage(
                storage_body_from_page(detail),
                public_text,
                date_value,
                author,
            )
            try:
                result = update_page(config, page_id, title, version_number, storage_html)
                break
            except ConfluenceHTTPError as exc:
                if exc.status_code == 409 and attempt < 3:
                    LOGGER.warning("publish.version_conflict_retry attempt=%s page_id=%s", attempt, page_id)
                    continue
                raise
        outcome = "updated"
    else:
        storage_html = markdown_public_to_storage(public_text, date_value, author)
        result = create_page(config, title, storage_html)
        outcome = "created"

    page_id = str(result.get("id") or "").strip()
    add_label(config, page_id)
    links = result.get("_links") if isinstance(result.get("_links"), dict) else {}
    url = web_url(config, str(links.get("webui") or ""), page_id)
    LOGGER.info("publish.done outcome=%s page_id=%s url=%s", outcome, page_id, url)
    print(json.dumps({"outcome": outcome, "page_id": page_id, "url": url}, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage local Daily Work docs.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    add_parser = subparsers.add_parser("add", help="Append to today's Daily Work file.")
    add_parser.add_argument("--date", default="", help="Date in YYYY-MM-DD format.")
    add_parser.add_argument("--author", default="", help="Author slug for the local Daily Work file.")
    add_parser.add_argument("--public", default="", help="Safe public digest entry.")
    add_parser.add_argument("--internal", default="", help="Local internal log entry.")
    add_parser.add_argument("--skip-empty", action="store_true", help="Do nothing if both entries are empty.")
    add_parser.set_defaults(func=add_entry)

    status_parser = subparsers.add_parser("status", help="Show safe Daily Work status.")
    status_parser.add_argument("--date", default="", help="Date in YYYY-MM-DD format.")
    status_parser.add_argument("--author", default="", help="Author slug for the local Daily Work file.")
    status_parser.add_argument("--file", default="", help="Explicit Daily Work file path.")
    status_parser.set_defaults(func=status)

    publish_parser = subparsers.add_parser("publish", help="Publish Public digest to Confluence.")
    publish_parser.add_argument("--date", default="", help="Date in YYYY-MM-DD format.")
    publish_parser.add_argument("--author", default="", help="Author slug for the local Daily Work file.")
    publish_parser.add_argument("--file", default="", help="Explicit Daily Work file path.")
    publish_parser.add_argument("--dry-run", action="store_true", help="Validate without calling Confluence.")
    publish_parser.add_argument(
        "--allow-unsafe-public-digest",
        action="store_true",
        help="Override unsafe-marker refusal. Use only after manual review.",
    )
    publish_parser.set_defaults(func=publish)
    return parser


def main(argv: list[str] | None = None) -> int:
    load_local_env_file()
    configure_logging()
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except DailyWorkError as exc:
        LOGGER.error("failed reason=%s", exc)
        return 1


if __name__ == "__main__":
    sys.exit(main())
