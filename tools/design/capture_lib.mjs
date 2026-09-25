// Pure helpers for capture_screens.mjs. No browser here, so node --test covers them.
import path from 'node:path';

const STEP_LABEL = /^(.*) · (\d+)\/(\d+)$/;
const SCREEN_NUMBER = /^\d{2}$/;

/** The label the kit shows, with no stepper, on a screen drawn in one state. */
const SINGLE_STATE = 'Single state';

/** "Root · decks · 1/22" → { label: "Root · decks", index: 1, total: 22 }. */
export function parseStepLabel(text) {
  if (text.trim() === SINGLE_STATE) {
    return { label: SINGLE_STATE, index: 1, total: 1 };
  }
  const match = STEP_LABEL.exec(text.trim());
  if (!match) throw new Error(`Unrecognised state label: "${text}"`);
  return { label: match[1], index: Number(match[2]), total: Number(match[3]) };
}

/** The frame's own caption decides its theme, never its position. */
export function frameTheme(themeLabel) {
  const value = themeLabel.trim().toLowerCase();
  if (value.startsWith('light')) return 'light';
  if (value.startsWith('dark')) return 'dark';
  throw new Error(`Unrecognised theme label: "${themeLabel}"`);
}

export function imagePath(outDir, screenDir, stateId, theme) {
  return path.join(outDir, screenDir, `${stateId}-${theme}.png`);
}

/** Checks the manifest and returns its screens. */
export function validateManifest(manifest) {
  if (!manifest || !Array.isArray(manifest.screens)) {
    throw new Error('Manifest must hold a "screens" array');
  }
  for (const screen of manifest.screens) {
    if (!SCREEN_NUMBER.test(screen.num ?? '')) {
      throw new Error(`Invalid screen number "${screen.num}": expected two digits`);
    }
    const ids = new Set();
    const labels = new Set();
    for (const state of screen.states) {
      if (ids.has(state.id)) {
        throw new Error(`Screen ${screen.num}: duplicate state id "${state.id}"`);
      }
      if (labels.has(state.label)) {
        throw new Error(`Screen ${screen.num}: duplicate state label "${state.label}"`);
      }
      ids.add(state.id);
      labels.add(state.label);
    }
  }
  return manifest.screens;
}

/** The wanted states whose label the stepper never showed. */
export function missingStates(screen, seenLabels) {
  return screen.states
    .filter((state) => !seenLabels.has(state.label))
    .map((state) => `${state.id} ("${state.label}")`);
}
