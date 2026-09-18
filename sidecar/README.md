# The Book Tool — AI sidecar

A small local HTTP server that gives the app access to any model Python can
reach: Claude through the Claude Agent SDK, Claude through the Anthropic API,
or anything `litellm` supports.

## Why it is a separate process

The macOS build is sandboxed (`com.apple.security.app-sandbox`), so the app
cannot launch an external Python interpreter. It *can* open loopback
connections (`com.apple.security.network.client`), so the sidecar runs on its
own and the app connects to it.

That also means the sidecar is entirely optional — the app's OpenAI and
Anthropic backends work without it.

## Setup

```bash
cd sidecar
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt   # or just the one provider you want
```

Providers are picked up only if importable, so installing a subset is fine.

| Provider | Install | Credentials |
|---|---|---|
| `claude-agent-sdk` | `pip install claude-agent-sdk` | Your Claude Code login — no API key |
| `anthropic` | `pip install anthropic` | `ANTHROPIC_API_KEY` |
| `litellm` | `pip install litellm` | That provider's usual env vars |

The Claude Agent SDK shells out to the `claude` CLI, so Claude Code must be
installed and logged in for that provider to work.

## Run

```bash
python3 book_tool_sidecar.py
# Listening on http://127.0.0.1:8787
# Providers: claude-agent-sdk, anthropic
```

Options: `--host`, `--port`, `--token` (require `Authorization: Bearer ...`),
`--verbose`.

## Point the app at it

Settings → **AI** tab:

- **Backend**: Python sidecar
- **Sidecar URL**: `http://127.0.0.1:8787`
- **Sidecar provider**: `claude-agent-sdk`
- **AI Model**: `claude-opus-5`
- Press **Test** — it should read `Connected · claude-agent-sdk, anthropic`,
  and the model dropdown fills with what the sidecar advertises.

## Protocol

```
GET /health
  -> 200 {"status": "ok",
          "providers": {"claude-agent-sdk": {"models": ["claude-opus-5", ...]}}}

POST /v1/complete
  {"provider": "claude-agent-sdk", "model": "claude-opus-5",
   "system": "...", "prompt": "...", "max_tokens": 4096}
  -> 200 {"text": "...", "model": "claude-opus-5",
          "usage": {"input_tokens": 1234, "output_tokens": 567},
          "cost_usd": 0.0231}
  -> 4xx/5xx {"error": "..."}
```

`cost_usd` is optional. When present the app trusts it; when absent the app
prices the call from its own table. A subscription-backed Agent SDK run
reporting `0.0` is meaningful and different from omitting the field.

## Adding a provider

Subclass `Provider` in `book_tool_sidecar.py`, implement `available()` and
`complete()`, and append an instance to `PROVIDERS`. The app discovers it from
`/health` — no Dart changes needed.

```python
class MyProvider(Provider):
    name = "my-provider"
    models = ["my-model-v1"]

    def available(self) -> bool:
        return True

    def complete(self, system, prompt, model, max_tokens) -> Completion:
        return Completion(text="...", model=model)
```

## Security note

Bind to `127.0.0.1` (the default). The server has no authentication unless you
pass `--token`, so do not expose it on a network interface.
