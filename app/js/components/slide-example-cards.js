import { BaseSlide } from "./base-slide.js";

class SlideExampleCards extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .grid {
      display: grid;
      gap: 14px;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      margin-top: 18px;
    }
    .card-ex {
      background: var(--card, rgba(255,255,255,0.04));
      border: 1px solid rgba(240,192,96,0.18);
      border-radius: 14px;
      padding: 18px;
      text-align: center;
      transition: all 0.2s;
    }
    .card-ex:hover { transform: translateY(-2px); border-color: var(--gold); }
    .ar { font-family: 'Noto Naskh Arabic', serif; color: var(--gold); font-size: 24px; font-weight: 700; margin-bottom: 8px; }
    .sep { color: var(--muted, #8880a0); font-size: 18px; margin: 6px 0; }
    .he { color: var(--text); font-size: 16px; }
    .note { color: var(--muted, #8880a0); font-size: 12px; margin-top: 8px; font-style: italic; }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const items = Array.isArray(c.items) ? c.items : [];
    return `
      <div class="wrap card">
        ${c.title ? `<div class="h-title">${e(c.title)}</div>` : ""}
        <div class="grid">
          ${items.map(it => `
            <div class="card-ex">
              <div class="ar">${e(it.arabic_phrase)}</div>
              ${it.separator ? `<div class="sep">${e(it.separator)}</div>` : ""}
              <div class="he">${e(it.hebrew_translation)}</div>
              ${it.translation_note ? `<div class="note">${e(it.translation_note)}</div>` : ""}
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }
}

customElements.define("slide-example-cards", SlideExampleCards);
