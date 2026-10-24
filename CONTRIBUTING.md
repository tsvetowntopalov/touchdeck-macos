# Contributing to TouchDeck

Thanks for your interest! Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an issue with the **Bug report** template. Please include:

- your macOS version and Mac model
- which trackpad you use (built-in or Magic Trackpad)
- what the ✋ menu shows (Accessibility, Hotkey, Trackpad lines)
- what you did, what you expected, and what happened instead

TouchDeck relies on private macOS frameworks, so the macOS version matters a lot.

## Setting up

```bash
brew install xcodegen
make open    # generates TouchDeck.xcodeproj and opens it in Xcode
```

`TouchDeck.xcodeproj` is generated from `project.yml` and is not committed. Change build settings in `project.yml`, not in Xcode, then run `make gen`.

To stop macOS dropping the Accessibility permission on every rebuild, sign with your own team. See [Keep the permission across rebuilds](README.md#keep-the-permission-across-rebuilds-optional). Never commit `Config/Local.xcconfig`.

## Making changes

1. Fork the repo and create a branch from `main`.
2. Keep each pull request to one change.
3. Match the surrounding code: small types, a short doc comment on anything non-obvious, no force unwraps of private-API lookups.
4. Geometry belongs in `DeckLayout`. Don't hard-code positions in the view or in hit-testing.
5. Make sure `make build` succeeds with no new warnings.
6. Test on a real trackpad: open the deck, drag each slider, tap and click keys, and check the cursor comes back when you release ⌃⌥.
7. Update the README if behavior or setup changes, and add a line to `CHANGELOG.md` under **Unreleased**.

## Private APIs

TouchDeck uses MultitouchSupport, DisplayServices and a private CoreGraphics connection property. When you add a private call:

- resolve it at runtime with `dlopen`/`dlsym`, never link it
- fail quietly (return `nil` or do nothing) if the symbol is missing
- say in a comment what it does and where the signature comes from

## Code of conduct

Be kind and assume good intent. Harassment or personal attacks aren't tolerated.
