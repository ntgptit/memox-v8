// Tests for capture_lib.mjs:  node --test 'tools/design/*.test.mjs'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import {
  parseStepLabel,
  frameTheme,
  imagePath,
  validateManifest,
  missingStates,
} from './capture_lib.mjs';

test('parseStepLabel keeps the separators inside the label', () => {
  assert.deepEqual(parseStepLabel('Root · decks · 1/22'), {
    label: 'Root · decks',
    index: 1,
    total: 22,
  });
  assert.deepEqual(parseStepLabel('  Empty · 5/5 '), {
    label: 'Empty',
    index: 5,
    total: 5,
  });
});

test('parseStepLabel rejects a label without a position', () => {
  assert.throws(() => parseStepLabel('Root · decks'), /Unrecognised state label/);
});

test('frameTheme reads the theme label, not the frame order', () => {
  assert.equal(frameTheme('Dark · Tokyo Nebula'), 'dark');
  assert.equal(frameTheme('LIGHT · TOKYO PURE'), 'light');
  assert.throws(() => frameTheme('Sepia'), /Unrecognised theme label/);
});

test('imagePath names a state image', () => {
  assert.equal(
    imagePath('out', '01-deck-list', 'rootLoaded', 'dark'),
    path.join('out', '01-deck-list', 'rootLoaded-dark.png'),
  );
});

test('validateManifest rejects a duplicate state id', () => {
  const manifest = {
    screens: [
      {
        num: '01',
        dir: '01-a',
        title: 'A',
        states: [
          { id: 'x', label: 'One' },
          { id: 'x', label: 'Two' },
        ],
      },
    ],
  };
  assert.throws(() => validateManifest(manifest), /duplicate state id "x"/);
});

test('validateManifest rejects a duplicate state label', () => {
  const manifest = {
    screens: [
      {
        num: '01',
        dir: '01-a',
        title: 'A',
        states: [
          { id: 'x', label: 'One' },
          { id: 'y', label: 'One' },
        ],
      },
    ],
  };
  assert.throws(() => validateManifest(manifest), /duplicate state label "One"/);
});

test('validateManifest rejects a screen number that is not two digits', () => {
  const manifest = { screens: [{ num: '1', dir: 'a', title: 'A', states: [] }] };
  assert.throws(() => validateManifest(manifest), /screen number "1"/);
});

test('missingStates lists the wanted labels never seen', () => {
  const screen = {
    num: '04',
    dir: '04-x',
    title: 'X',
    states: [
      { id: 'a', label: 'Empty' },
      { id: 'b', label: 'Error' },
    ],
  };
  assert.deepEqual(missingStates(screen, new Set(['Empty'])), ['b ("Error")']);
});

test('the committed manifest lists the V8 states of 01, 02, 04 and 07', () => {
  const file = new URL('./screen_states.json', import.meta.url);
  const screens = validateManifest(JSON.parse(readFileSync(file, 'utf8')));
  assert.deepEqual(
    screens.map((screen) => [screen.num, screen.states.length]),
    [
      ['01', 20],
      ['02', 9],
      ['04', 5],
      ['07', 13],
    ],
  );
});
