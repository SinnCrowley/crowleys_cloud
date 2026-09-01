<!-- Copyright (C) 2026 Sinn Crowley
     AGPL-3.0-or-later -->

<script>
  import { onMount } from 'svelte';
  import { decodeBlurHashToImageData, isValidBlurHash } from '../utils/blurhash.js';

  export let blurhash = '';
  export let width = 32;
  export let height = 32;
  export let punch = 1.0;

  let canvasEl;

  function renderHash(hash) {
    if (!canvasEl || !hash || !isValidBlurHash(hash)) return;
    try {
      const imageData = decodeBlurHashToImageData(hash, width, height, punch);
      if (imageData) {
        const ctx = canvasEl.getContext('2d', { alpha: false });
        if (ctx) {
          ctx.putImageData(imageData, 0, 0);
        }
      }
    } catch (err) {
      console.warn('BlurHash render error:', err);
    }
  }

  $: if (canvasEl && blurhash) {
    renderHash(blurhash);
  }

  onMount(() => {
    if (blurhash) {
      renderHash(blurhash);
    }
  });
</script>

<canvas
  bind:this={canvasEl}
  {width}
  {height}
  class="blurhash-canvas"
  aria-hidden="true"
></canvas>

<style>
  .blurhash-canvas {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
    pointer-events: none;
    image-rendering: auto;
    filter: blur(4px);
    transform: scale(1.08);
  }
</style>
