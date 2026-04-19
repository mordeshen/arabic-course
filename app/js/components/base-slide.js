// ──────────────────────────────────────────────────────────────
// BaseSlide — common scaffolding for slide Web Components
// Subclasses set static `template(content)` returning HTML for shadow DOM
// and optionally override `afterRender(content, root)` for behavior.
// ──────────────────────────────────────────────────────────────

const SHARED_STYLE = `
  :host {
    display: block;
    width: 100%;
    color: var(--text, #e8e0d0);
    font-family: 'Heebo', sans-serif;
  }
  * { box-sizing: border-box; }
  h1, h2, h3 { font-family: 'Heebo', sans-serif; font-weight: 900; }
  .arabic { font-family: 'Noto Naskh Arabic', serif; direction: rtl; }
  .highlight { color: var(--gold, #f0c060); font-weight: 700; }
  .teal      { color: var(--teal, #3de8d0); font-weight: 700; }
  .rose      { color: var(--rose, #ff6b8a); font-weight: 700; }
  .gold      { color: var(--gold, #f0c060); font-weight: 700; }
  .card {
    background: var(--card, rgba(255,255,255,0.04));
    border: 1px solid rgba(240,192,96,0.18);
    border-radius: 18px;
    padding: 24px;
    margin: 14px 0;
  }
  .h-title {
    color: var(--gold, #f0c060);
    font-size: 22px;
    font-weight: 900;
    margin-bottom: 12px;
    text-align: center;
  }
`;

export class BaseSlide extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
    this._content = null;
    this._lesson = null;
  }

  set content(v) { this._content = v || {}; this._render(); }
  get content() { return this._content; }

  set lesson(v) { this._lesson = v; }
  get lesson() { return this._lesson; }

  connectedCallback() {
    if (this._content && !this._rendered) this._render();
  }

  _render() {
    if (!this.shadowRoot) return;
    const inner = this.constructor.template(this._content || {}, this._lesson || {});
    this.shadowRoot.innerHTML = `<style>${SHARED_STYLE}${this.constructor.styles || ""}</style>${inner}`;
    this._rendered = true;
    if (typeof this.afterRender === "function") {
      this.afterRender(this._content || {}, this.shadowRoot);
    }
  }

  // Convenience escapers for subclasses
  static esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]));
  }
}
