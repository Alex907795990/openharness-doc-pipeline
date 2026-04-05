"""Filesystem globbing tool."""

from __future__ import annotations

from pathlib import Path

from pydantic import BaseModel, Field

from openharness.tools.base import BaseTool, ToolExecutionContext, ToolResult


class GlobToolInput(BaseModel):
    """Arguments for the glob tool."""

    pattern: str = Field(description="Glob pattern relative to the working directory")
    root: str | None = Field(default=None, description="Optional search root")
    limit: int = Field(default=200, ge=1, le=5000)


class GlobTool(BaseTool):
    """List files matching a glob pattern."""

    name = "glob"
    description = "List files matching a glob pattern."
    input_model = GlobToolInput

    def is_read_only(self, arguments: GlobToolInput) -> bool:
        del arguments
        return True

    async def execute(self, arguments: GlobToolInput, context: ToolExecutionContext) -> ToolResult:
        root = _resolve_path(context.cwd, arguments.root) if arguments.root else context.cwd
        
        # pathlib.glob() does not support absolute patterns.
        # If the model passes an absolute pattern, we try to make it relative to root.
        pattern = arguments.pattern
        if Path(pattern).is_absolute():
            try:
                pattern = str(Path(pattern).relative_to(root))
            except ValueError:
                # If it's absolute but not under root, we can't easily glob it from root.
                # Just strip the leading slash as a best-effort fallback for root.glob
                pattern = pattern.lstrip("/")
                if ":" in pattern:  # Windows drive letter fallback
                    pattern = pattern.split(":", 1)[1].lstrip("\\/")

        matches = sorted(
            str(path.relative_to(root))
            for path in root.glob(pattern)
        )
        if not matches:
            return ToolResult(output="(no matches)")
        return ToolResult(output="\n".join(matches[: arguments.limit]))


def _resolve_path(base: Path, candidate: str | None) -> Path:
    path = Path(candidate or ".").expanduser()
    if not path.is_absolute():
        path = base / path
    return path.resolve()
