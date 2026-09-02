import { describe, expect, it } from 'vitest';
import { escapeHtml } from '../src/utils/escapeHtml.js';

describe('escapeHtml', () => {
  it('renders markup-like input as text for HTML email templates', () => {
    expect(escapeHtml('<img src=x onerror="alert(1)">\n&')).toBe(
      '&lt;img src=x onerror=&quot;alert(1)&quot;&gt;\n&amp;',
    );
  });
});
