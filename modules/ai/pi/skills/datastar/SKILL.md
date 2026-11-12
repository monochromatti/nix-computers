---
name: datastar
description: "Datastar hypermedia UI: data-on:/data-bind/data-signals attributes, @get/@post actions, SSE element and signal patches, datastar-py and other Datastar SDKs."
---

# Datastar

Datastar is a hypermedia framework. The backend holds the state and drives the page by patching HTML elements and signals into it; the browser holds only interaction state. There is no need for a client-side store, JSON-to-DOM rendering, or hand-written DOM updates, because the backend sends the rendered result.

## The Datastar way

Bind inputs to signals to send new state; prefix browser-only signals with `_` so they stay local. Data copied into signals goes stale, so fetch it from the backend when it is needed.

Use a fat morph: send a complete fragment, up to the whole `<main>` or `<html>`; the morph only touches what changed. Complete fragments also survive dropped connections, which append-style patches do not. Compress the SSE stream with Brotli so this stays cheap.

For live or collaborative views, use CQRS: one long-lived `@get` opened by `data-init` streams the current view, and buttons send short `@post`s that change state without returning UI. The stream delivers the result.

```html
<div id="main" data-init="@get('/updates')">
  <button data-on:click="el.classList.add('loading'); @post('/do')">Do</button>
</div>
```

Let the backend confirm every change and show a loading indicator until it does (`data-indicator:_loading`, or a class the next morph removes). Optimistic UI would show a success that may be rolled back a moment later.

Each page is a resource, so navigation is `<a href>` and the browser keeps history; a client router has nothing to do. Redirects from an action are a patched script (`execute_script`, or `SSE.redirect` in datastar-py).

Datastar has no loop or template attribute because the backend template already has them. Use a variable or loop there, or one `data-on:click` on a parent that reads `evt.target`.

When behaviour needs real JavaScript, such as a chart, a third-party widget, or logic that only runs in the browser, wrap it in a web component. Expressions then stay short, and the component's state stays inside it. Connect it with props down, events up: `data-attr:*` sets its attributes, `data-on:*` listens for the events it dispatches, and `data-bind` uses its `value` and `change` (or `__prop`/`__event`).

```html
<reverse-component data-attr:name="$_name" data-on:reverse="$_reversed = evt.detail.value"></reverse-component>
```

A finished design passes two checks: every signal is interaction state, and every non-default option or line of custom JavaScript has a reason the how-tos and `/examples` could not supply.

## Syntax

`data-{plugin}:{key}__{modifier}.{tag}="expression"`: `data-on:click`, `data-bind:query`, `data-on:input__debounce.300ms`, `data-on-interval__duration.5s`, `data-attr:aria-expanded`. `$name` reads a signal, `@get(...)` calls an action, `evt` and `el` are in scope. Pre-1.0 names (`data-on-click`, `data-on-load`, `datastar-merge-fragments`, `datastar-merge-signals`) are stale; the current ones are `data-on:click`, `data-init`, `datastar-patch-elements`, `datastar-patch-signals`.

Respond with `text/event-stream` via the SDK; one stream can carry any number of element, signal and script patches, so other content types gain nothing. A patch morphs the element with the same `id`; `selector` and `mode` are for cases like appending list items.

## Researching

Find the pinned version (script tag URL or lockfile); the API changed significantly before 1.0.

- `curl -s https://data-star.dev/docs.md` is the latest release's guide, Tao and reference in one file; `grep -n '^#'` for the outline.
- How-tos (`/how_tos/`) and `/examples` are not in it.
- For SDK APIs, read the installed package, e.g. `sse.py` in the directory printed by `python -c "import datastar_py; print(datastar_py.__path__[0])"`, or its repo under `github.com/starfederation`.
- For browser behaviour, read the pinned bundle source in `starfederation/datastar` at the matching tag.
