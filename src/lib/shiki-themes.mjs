// Code colours follow the design tokens for syntax (light and dark).
const theme = (name, type, c) => ({
  name,
  type,
  colors: { 'editor.background': '#00000000', 'editor.foreground': c.text },
  tokenColors: [
    { scope: ['comment', 'punctuation.definition.comment'], settings: { foreground: c.com } },
    { scope: ['keyword', 'storage', 'keyword.control'], settings: { foreground: c.kw } },
    { scope: ['string', 'string.quoted'], settings: { foreground: c.str } },
    { scope: ['constant.numeric', 'constant.language'], settings: { foreground: c.num } },
    { scope: ['entity.name.function', 'support.function', 'meta.function-call'], settings: { foreground: c.fn } },
  ],
});
export const matlabLight = theme('simply-light', 'light', { text: '#111114', kw: '#9B2393', str: '#B3150F', num: '#1C00CF', com: '#5D6C79', fn: '#2D6870' });
export const matlabDark = theme('simply-dark', 'dark', { text: '#ECECF1', kw: '#FC5FA3', str: '#FC6A5D', num: '#D0BF69', com: '#8A96A2', fn: '#67B7A4' });
