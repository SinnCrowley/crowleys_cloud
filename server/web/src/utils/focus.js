// Copyright (C) 2026 Sinn Crowley
// AGPL-3.0-or-later

/**
 * Svelte action to autofocus an element when mounted into the DOM.
 * Optionally selects all text if select is true.
 *
 * @param {HTMLElement} node
 * @param {{ select?: boolean }} options
 */
export function autofocus(node, { select = false } = {}) {
  const focusElement = () => {
    if (!node) return;
    node.focus();
    if (select && typeof node.select === 'function') {
      node.select();
    }
  };

  // Immediate attempt
  focusElement();

  // Retry on next animation frame and a short microtask delay
  // to ensure transitions, dialog animations, and DOM rendering have completed.
  const rafId = requestAnimationFrame(() => {
    focusElement();
  });
  const timerId = setTimeout(focusElement, 40);

  return {
    destroy() {
      cancelAnimationFrame(rafId);
      clearTimeout(timerId);
    }
  };
}

/**
 * Svelte action specifically for filename rename inputs:
 * focuses the input and selects only the filename excluding the extension.
 * E.g., for "vacation.photo.jpg", selects "vacation.photo".
 * For folders or files without dot, selects the whole string.
 *
 * @param {HTMLInputElement} node
 */
export function autofocusRename(node) {
  const focusAndSelectName = () => {
    if (!node) return;
    node.focus();
    const val = node.value || '';
    const lastDotIndex = val.lastIndexOf('.');

    if (lastDotIndex > 0) {
      // Select filename up to the extension
      node.setSelectionRange(0, lastDotIndex);
    } else if (typeof node.select === 'function') {
      node.select();
    }
  };

  focusAndSelectName();

  const rafId = requestAnimationFrame(() => {
    focusAndSelectName();
  });
  const timerId = setTimeout(focusAndSelectName, 40);

  return {
    destroy() {
      cancelAnimationFrame(rafId);
      clearTimeout(timerId);
    }
  };
}
