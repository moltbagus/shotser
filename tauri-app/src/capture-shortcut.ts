export type ShortcutKeyboardEvent = {
  key: string;
  code?: string;
  metaKey?: boolean;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
};

const namedKeys: Record<string, string> = {
  Space: "Space",
  Backquote: "Backquote",
  Minus: "Minus",
  Equal: "Equal",
  BracketLeft: "BracketLeft",
  BracketRight: "BracketRight",
  Backslash: "Backslash",
  Semicolon: "Semicolon",
  Quote: "Quote",
  Comma: "Comma",
  Period: "Period",
  Slash: "Slash",
  IntlBackslash: "IntlBackslash",
  NumpadAdd: "NumpadAdd",
  NumpadSubtract: "NumpadSubtract",
  NumpadMultiply: "NumpadMultiply",
  NumpadDivide: "NumpadDivide",
  NumpadDecimal: "NumpadDecimal",
  NumpadEnter: "NumpadEnter",
};

function shortcutKeyName(event: ShortcutKeyboardEvent) {
  const code = event.code ?? "";
  const alpha = code.match(/^Key([A-Z])$/);
  if (alpha) return alpha[1];
  const digit = code.match(/^(?:Digit|Numpad)([0-9])$/);
  if (digit) return code.startsWith("Numpad") ? `Numpad${digit[1]}` : digit[1];
  if (/^F(?:[1-9]|1[0-9]|2[0-4])$/.test(code)) return code;
  if (namedKeys[code]) return namedKeys[code];
  if (event.key === " ") return "Space";
  if (event.key.length === 1 && /^[A-Z0-9]$/i.test(event.key)) return event.key.toUpperCase();
  return null;
}

/** Convert a browser key event into a platform-neutral global-hotkey string. */
export function shortcutFromKeyboardEvent(event: ShortcutKeyboardEvent) {
  const key = shortcutKeyName(event);
  if (!key) return null;
  const modifiers = [
    event.metaKey ? "Command" : event.ctrlKey ? "Control" : null,
    event.altKey ? "Alt" : null,
    event.shiftKey ? "Shift" : null,
  ].filter((modifier): modifier is string => Boolean(modifier));
  return modifiers.length ? [...modifiers, key].join("+") : null;
}
