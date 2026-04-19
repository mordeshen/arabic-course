import { BaseSlide } from "./base-slide.js";

class SlideVocabGrid extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .grid {
      display: grid;
      gap: 14px;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      margin-top: 18px;
    }
    .item {
      background: var(--card, rgba(255,255,255,0.04));
      border: 1px solid rgba(240,192,96,0.2);
      border-radius: 14px;
      padding: 18px 14px;
      text-align: center;
      cursor: pointer;
      transition: all 0.25s;
    }
    .item:hover {
      background: rgba(240,192,96,0.08);
      transform: translateY(-3px);
      border-color: var(--gold);
    }
    .item.flipped { background: rgba(61,232,208,0.08); border-color: var(--teal); }
    .ar { font-family: 'Noto Naskh Arabic', serif; color: var(--gold); font-size: 26px; font-weight: 700; margin-bottom: 6px; }
    .item.flipped .ar { color: var(--teal); }
    .he { color: var(--text); font-size: 16px; }
    .tr { color: var(--muted, #8880a0); font-size: 12px; margin-top: 4px; font-style: italic; }
    .hint { text-align: center; color: var(--muted, #8880a0); font-size: 13px; margin-top: 12px; }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const items = Array.isArray(c.items) ? c.items : [];
    return `
      <div class="wrap card">
        ${c.title ? `<div class="h-title">${e(c.title)}</div>` : ""}
        <div class="grid">
          ${items.map(it => `
            <div class="item">
              <div class="ar">${e(it.arabic)}</div>
              <div class="he">${e(it.hebrew)}</div>
              ${it.transliteration ? `<div class="tr">${e(it.transliteration)}</div>` : ""}
            </div>
          `).join("")}
        </div>
        <div class="hint">לחצו על כרטיס לסימון</div>
      </div>
    `;
  }

  afterRender(_c, root) {
    root.querySelectorAll(".item").forEach(el => {
      el.addEventListener("click", () => el.classList.toggle("flipped"));
    });
  }
}

customElements.define("slide-vocab-grid", SlideVocabGrid);
