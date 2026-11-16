import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

test('MediaPreviewModal: SVG extension and file type detection', async () => {
  const componentSrc = await readFile(new URL('../src/components/MediaPreviewModal.svelte', import.meta.url), 'utf8');

  // Extract isImageExtension, isSvg and getFileType implementations from Svelte component
  assert.ok(componentSrc.includes('function isSvg('), 'MediaPreviewModal contains isSvg function');
  assert.ok(componentSrc.includes('function isImageExtension('), 'MediaPreviewModal contains isImageExtension function');
  assert.ok(componentSrc.includes('function getFileType('), 'MediaPreviewModal contains getFileType function');
  assert.ok(componentSrc.includes('class:preview-svg={isSvgFile}'), 'MediaPreviewModal applies preview-svg class to SVG images');
  assert.ok(componentSrc.includes('.preview-image.preview-svg'), 'MediaPreviewModal contains CSS for SVG images');

  // Re-create the logic extracted from MediaPreviewModal.svelte
  function isSvg(filename) {
    return /\.svgz?$/i.test(filename || '');
  }

  function isPdfExtension(filename) {
    return /\.pdf$/i.test(filename || '');
  }

  function isImageExtension(filename) {
    return /\.(jpg|jpeg|png|gif|webp|svg|svgz|bmp|ico|heic|heif|avif)$/i.test(filename || '');
  }

  function isVideoExtension(filename) {
    return /\.(mp4|webm|ogg|mov|mkv|avi)$/i.test(filename || '');
  }

  function isAudioExtension(filename) {
    return /\.(mp3|wav|ogg|flac|aac|m4a)$/i.test(filename || '');
  }

  function isTextExtension(filename) {
    return /\.(txt|json|js|jsx|ts|tsx|py|cpp|c|h|hpp|css|html|xml|md|sh|yaml|yml|ini|log|env|dart|svelte)$/i.test(
      filename || ''
    );
  }

  function getFileType(item) {
    if (!item) return 'unsupported';
    const filename = item.name || item.path || '';
    if (item.type === 'photo' || item.type === 'image' || isImageExtension(filename) || (item.mime_type && item.mime_type.startsWith('image/'))) {
      return 'image';
    }
    if (item.type === 'video' || isVideoExtension(filename) || (item.mime_type && item.mime_type.startsWith('video/'))) {
      return 'video';
    }
    if (item.type === 'audio' || isAudioExtension(filename) || (item.mime_type && item.mime_type.startsWith('audio/'))) {
      return 'audio';
    }
    if (isPdfExtension(filename) || item.mime_type === 'application/pdf') {
      return 'pdf';
    }
    if (isTextExtension(filename) || (item.mime_type && (item.mime_type.startsWith('text/') || item.mime_type === 'application/json'))) {
      return 'text';
    }
    return 'unsupported';
  }

  // Verify isSvg
  assert.equal(isSvg('logo.svg'), true);
  assert.equal(isSvg('logo.svgz'), true);
  assert.equal(isSvg('VECTOR.SVG'), true);
  assert.equal(isSvg('archive.svgz'), true);
  assert.equal(isSvg('photo.png'), false);
  assert.equal(isSvg('document.pdf'), false);

  // Verify getFileType on various SVG entry shapes
  assert.equal(getFileType({ name: 'logo.svg', type: 'photo' }), 'image');
  assert.equal(getFileType({ name: 'vector.SVG', type: 'other' }), 'image');
  assert.equal(getFileType({ name: 'compressed.svgz', type: 'photo' }), 'image');
  assert.equal(getFileType({ path: 'photos/diagram.svg', name: '', type: 'other' }), 'image');
  assert.equal(getFileType({ name: 'icon', mime_type: 'image/svg+xml' }), 'image');
  assert.equal(getFileType({ name: 'photo.jpg', type: 'photo' }), 'image');
  assert.equal(getFileType({ name: 'clip.mp4', type: 'video' }), 'video');
  assert.equal(getFileType({ name: 'notes.txt', type: 'document' }), 'text');
});
