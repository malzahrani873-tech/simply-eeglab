// Glossary hints: a compound term wins over the single word inside it, and protected phrases get no hint.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import rehypeTerms from '../../src/lib/rehype-terms.mjs';

const hinted = (lang, value) => {
  const tree = { type: 'root', children: [{ type: 'element', tagName: 'p', properties: {}, children: [{ type: 'text', value }] }] };
  rehypeTerms()(tree, { path: `content/lessons/${lang}/00-00-x.mdx` });
  return tree.children[0].children.filter((n) => n.tagName === 'button').map((n) => n.properties.popoverTarget);
};

test('a compound term wins over the word inside it', () => {
  assert.deepEqual(hinted('en', 'The line noise peak is at 60 Hz.'), ['term-line-noise']);
  assert.deepEqual(hinted('ar', 'تظهر ضوضاء الكهرباء عند 60 هرتز.'), ['term-line-noise']);
});

test('a protected phrase gives no hint for the word inside it', () => {
  assert.deepEqual(hinted('en', 'Noise from the power line is strong.'), ['term-noise']);
  assert.deepEqual(hinted('en', 'Alpha power rises with eyes closed.'), ['term-power']);
});
