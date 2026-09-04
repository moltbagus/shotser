type ShortcutRecovery = {
  shortcut: string;
  clearStored: boolean;
};

export function shortcutApplyAccepted(message: string): boolean {
  return message.startsWith("Capture shortcut set to") || message.startsWith("Capture shortcut is already");
}

export function startupShortcutRecovery(requested: string, fallback: string, accepted: boolean): ShortcutRecovery {
  if (accepted || requested === fallback) {
    return { shortcut: requested, clearStored: false };
  }
  return { shortcut: fallback, clearStored: true };
}
