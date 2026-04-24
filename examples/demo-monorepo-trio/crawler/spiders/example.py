"""Demo spider — replace with real crawler code."""
from typing import Any, Iterator


def parse(html: str) -> Iterator[dict[str, Any]]:
    yield {"title": "demo", "len": len(html)}
