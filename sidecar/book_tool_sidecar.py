#!/usr/bin/env python3
"""Local completion server for The Book Tool.

The Flutter app is sandboxed and cannot launch an interpreter, so this runs as
a separate process the user starts themselves. The app connects over loopback.

Adding a provider is the whole point of this file: subclass Provider, implement
``complete``, and add it to PROVIDERS. The app discovers whatever /health
advertises, so no Dart code changes.

Usage:
    python3 book_tool_sidecar.py                 # 127.0.0.1:8787
    python3 book_tool_sidecar.py --port 9000
    python3 book_tool_sidecar.py --token secret  # require a bearer token

Protocol:
    GET  /health       -> {"status": "ok", "providers": {name: {"models": [...]}}}
    POST /v1/complete  -> {"text", "model", "usage": {...}, "cost_usd"}
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import shutil
import sys
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

log = logging.getLogger("book-tool-sidecar")

# Bound every provider, so a runaway agent loop cannot bill forever.
DEFAULT_MAX_TOKENS = 4096


@dataclass
class Completion:
    """What every provider returns, in the shape the app expects."""

    text: str
    model: str
    input_tokens: int | None = None
    output_tokens: int | None = None
    # None means "you work it out from the model name"; 0.0 means "genuinely
    # free", which is the case for subscription-backed Agent SDK runs.
    cost_usd: float | None = None

    def to_json(self) -> dict[str, Any]:
        payload: dict[str, Any] = {"text": self.text, "model": self.model}
        if self.input_tokens is not None or self.output_tokens is not None:
            payload["usage"] = {
                "input_tokens": self.input_tokens or 0,
                "output_tokens": self.output_tokens or 0,
            }
        if self.cost_usd is not None:
            payload["cost_usd"] = self.cost_usd
        return payload


class Provider:
    """One way of turning a (system, prompt) pair into text."""

    name: str = "provider"
    models: list[str] = []

    def unavailable_reason(self) -> str | None:
        """None when this provider can serve requests, else why it cannot.

        Re-evaluated on every /health, so installing a package is picked up
        without restarting the server.
        """
        raise NotImplementedError

    def available(self) -> bool:
        return self.unavailable_reason() is None

    def complete(
        self, system: str, prompt: str, model: str, max_tokens: int
    ) -> Completion:
        raise NotImplementedError


class ClaudeAgentSDKProvider(Provider):
    """Claude via the Claude Agent SDK.

    The SDK drives the Claude Code harness, so this path uses the machine's
    Claude Code login rather than an API key. Tools are disabled: the app wants
    prose back, not file edits.

        pip install claude-agent-sdk
    """

    name = "claude-agent-sdk"
    models = ["claude-opus-5", "claude-sonnet-5", "claude-haiku-4-5"]

    def unavailable_reason(self) -> str | None:
        try:
            import claude_agent_sdk  # noqa: F401
        except ImportError:
            return "not installed (pip install claude-agent-sdk)"
        # The SDK shells out to the Claude Code CLI, so a missing `claude`
        # fails at request time rather than import time.
        if shutil.which("claude") is None:
            return "claude CLI not found (install Claude Code and log in)"
        return None

    def complete(
        self, system: str, prompt: str, model: str, max_tokens: int
    ) -> Completion:
        from claude_agent_sdk import ClaudeAgentOptions, query

        options = ClaudeAgentOptions(
            model=model,
            system_prompt=system,
            # A writing assistant has no business touching the filesystem.
            allowed_tools=[],
            max_turns=1,
        )

        async def run() -> Completion:
            chunks: list[str] = []
            input_tokens = output_tokens = 0
            cost: float | None = None

            async for message in query(prompt=prompt, options=options):
                # Assistant messages carry the prose.
                content = getattr(message, "content", None)
                if content:
                    for block in content:
                        text = getattr(block, "text", None)
                        if text:
                            chunks.append(text)

                # The final result message carries usage and cost.
                usage = getattr(message, "usage", None)
                if usage:
                    as_dict = usage if isinstance(usage, dict) else vars(usage)
                    input_tokens = as_dict.get("input_tokens", input_tokens) or 0
                    output_tokens = (
                        as_dict.get("output_tokens", output_tokens) or 0
                    )
                total_cost = getattr(message, "total_cost_usd", None)
                if total_cost is not None:
                    cost = float(total_cost)

            return Completion(
                text="".join(chunks).strip(),
                model=model,
                input_tokens=input_tokens or None,
                output_tokens=output_tokens or None,
                cost_usd=cost,
            )

        return asyncio.run(run())


class AnthropicProvider(Provider):
    """Claude via the Anthropic SDK, using ANTHROPIC_API_KEY.

    Mostly useful as a fallback when the Agent SDK is not installed.

        pip install anthropic
    """

    name = "anthropic"
    models = ["claude-opus-5", "claude-opus-4-8", "claude-sonnet-5", "claude-haiku-4-5"]

    def unavailable_reason(self) -> str | None:
        try:
            import anthropic  # noqa: F401
        except ImportError:
            return "not installed (pip install anthropic)"
        if not os.environ.get("ANTHROPIC_API_KEY"):
            return "ANTHROPIC_API_KEY is not set"
        return None

    def complete(
        self, system: str, prompt: str, model: str, max_tokens: int
    ) -> Completion:
        import anthropic

        client = anthropic.Anthropic()
        message = client.messages.create(
            model=model,
            max_tokens=max_tokens,
            system=system,
            messages=[{"role": "user", "content": prompt}],
        )

        if message.stop_reason == "refusal":
            raise RuntimeError("Claude declined this request.")

        text = "".join(
            block.text for block in message.content if block.type == "text"
        )
        return Completion(
            text=text.strip(),
            model=message.model,
            input_tokens=message.usage.input_tokens,
            output_tokens=message.usage.output_tokens,
        )


class LiteLLMProvider(Provider):
    """Anything litellm can reach: OpenAI, Gemini, Ollama, Bedrock, ...

    Model strings are litellm's own (``gemini/gemini-2.5-pro``,
    ``ollama/llama3``). Credentials come from that provider's usual env vars.

        pip install litellm
    """

    name = "litellm"
    models: list[str] = []  # Too many to enumerate; the user types one.

    def unavailable_reason(self) -> str | None:
        try:
            import litellm  # noqa: F401
        except ImportError:
            return "not installed (pip install litellm)"
        return None

    def complete(
        self, system: str, prompt: str, model: str, max_tokens: int
    ) -> Completion:
        import litellm

        response = litellm.completion(
            model=model,
            max_tokens=max_tokens,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": prompt},
            ],
        )

        usage = getattr(response, "usage", None)
        cost = None
        try:
            cost = litellm.completion_cost(completion_response=response)
        except Exception:  # pragma: no cover - pricing data is best-effort
            pass

        return Completion(
            text=(response.choices[0].message.content or "").strip(),
            model=getattr(response, "model", model),
            input_tokens=getattr(usage, "prompt_tokens", None),
            output_tokens=getattr(usage, "completion_tokens", None),
            cost_usd=cost,
        )


PROVIDERS: list[Provider] = [
    ClaudeAgentSDKProvider(),
    AnthropicProvider(),
    LiteLLMProvider(),
]


@dataclass
class Config:
    host: str = "127.0.0.1"
    port: int = 8787
    token: str = ""
    providers: list[Provider] = field(default_factory=list)

    def resolve(self) -> tuple[dict[str, Provider], dict[str, str]]:
        """Split providers into usable ones and reasons the rest are not.

        Recomputed per request, so `pip install`ing a provider takes effect
        without a restart.
        """
        usable: dict[str, Provider] = {}
        blocked: dict[str, str] = {}
        for provider in self.providers:
            reason = provider.unavailable_reason()
            if reason is None:
                usable[provider.name] = provider
            else:
                blocked[provider.name] = reason
        return usable, blocked


class Handler(BaseHTTPRequestHandler):
    config: Config

    # BaseHTTPRequestHandler logs every request to stderr; route it properly.
    def log_message(self, fmt: str, *args: Any) -> None:
        log.info("%s - %s", self.address_string(), fmt % args)

    def _send(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authorized(self) -> bool:
        if not self.config.token:
            return True
        header = self.headers.get("authorization", "")
        return header == f"Bearer {self.config.token}"

    def do_GET(self) -> None:  # noqa: N802 - name fixed by BaseHTTPRequestHandler
        if not self._authorized():
            self._send(401, {"error": "Unauthorized"})
            return

        if self.path.rstrip("/") == "/health":
            usable, blocked = self.config.resolve()
            self._send(
                200,
                {
                    "status": "ok",
                    "providers": {
                        name: {"models": provider.models}
                        for name, provider in usable.items()
                    },
                    "unavailable": blocked,
                },
            )
            return

        self._send(404, {"error": f"No such path: {self.path}"})

    def do_POST(self) -> None:  # noqa: N802
        if not self._authorized():
            self._send(401, {"error": "Unauthorized"})
            return

        if self.path.rstrip("/") != "/v1/complete":
            self._send(404, {"error": f"No such path: {self.path}"})
            return

        try:
            length = int(self.headers.get("content-length", 0))
            body = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError) as e:
            self._send(400, {"error": f"Malformed request body: {e}"})
            return

        providers, blocked = self.config.resolve()
        if not providers:
            detail = "; ".join(f"{n}: {r}" for n, r in blocked.items())
            self._send(
                503,
                {"error": f"No providers available. {detail}"},
            )
            return

        requested = body.get("provider") or next(iter(providers))
        provider = providers.get(requested)
        if provider is None:
            self._send(
                400,
                {
                    "error": f"Unknown provider '{requested}'. "
                    f"Available: {', '.join(providers)}"
                },
            )
            return

        model = body.get("model") or (
            provider.models[0] if provider.models else ""
        )
        if not model:
            self._send(400, {"error": "No model given and provider has no default."})
            return

        try:
            completion = provider.complete(
                system=body.get("system", ""),
                prompt=body.get("prompt", ""),
                model=model,
                max_tokens=int(body.get("max_tokens", DEFAULT_MAX_TOKENS)),
            )
        except Exception as e:  # Surface the real reason to the app.
            log.exception("Completion failed")
            self._send(502, {"error": f"{type(e).__name__}: {e}"})
            return

        self._send(200, completion.to_json())


def main() -> int:
    parser = argparse.ArgumentParser(description="The Book Tool AI sidecar")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument(
        "--token",
        default=os.environ.get("BOOK_TOOL_SIDECAR_TOKEN", ""),
        help="Require this bearer token on every request.",
    )
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    config = Config(
        host=args.host, port=args.port, token=args.token, providers=PROVIDERS
    )

    usable, blocked = config.resolve()
    for name, reason in blocked.items():
        log.warning("Provider %s unavailable: %s", name, reason)
    if usable:
        log.info("Providers: %s", ", ".join(usable))
    else:
        log.warning("No providers available - every request will return 503.")

    handler = type("BoundHandler", (Handler,), {"config": config})
    server = ThreadingHTTPServer((config.host, config.port), handler)

    log.info("Listening on http://%s:%d", config.host, config.port)
    if config.token:
        log.info("Bearer token required.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("Shutting down.")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
