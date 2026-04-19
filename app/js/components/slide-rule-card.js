import { BaseSlide } from "./base-slide.js";

class SlideRuleCard extends BaseSlide {
  static styles = `
    .wrap { padding: 20px 0; }
    .rule { font-size: 18px; line-height: 1.85; }
    .rule p { margin: 14px 0; }
    .examples { margin-top: 22px; display: grid; gap: 12px; grid-template-columns: 1fr; }
    @media (min-width: 640px) { .examples { grid-template-columns: 1fr 1fr; } }
    .ex {
      background: rgba(61,232,208,0.06);
      border: 1px solid rgba(61,232,208,0.25);
      border-radius: 14px;
      padding: 14px 18px;
      text-align: center;
    }
    .ex .ar { font-family: 'Noto Naskh Arabic', serif; color: var(--teal); font-size: 26px; margin-bottom: 4px; }
    .ex .he { color: var(--text); font-size: 15px; opacity: 0.85; }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const examples = Array.isArray(c.examples) ? c.examples : [];
    return `
      <div class="wrap card">
        ${c.title ? `<div class="h-title">${e(c.title)}</div>` : ""}
        <div class="rule">${c.html || ""}</div>
        ${examples.length ? `
          <div class="examples">
            ${examples.map(ex => `
              <div class="ex">
                <div class="ar">${e(ex.arabic)}</div>
                <div class="he">${e(ex.hebrew)}</div>
              </div>
            `).join("")}
          </div>
        ` : ""}
      </div>
    `;
  }
}

customElements.define("slide-rule-card", SlideRuleCard);
