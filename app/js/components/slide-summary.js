import { BaseSlide } from "./base-slide.js";

class SlideSummary extends BaseSlide {
  static styles = `
    .wrap { padding: 20px 0; }
    .heading { text-align: center; color: var(--gold); font-size: 28px; font-weight: 900; margin-bottom: 6px; }
    .subhead { text-align: center; color: var(--muted, #8880a0); font-size: 14px; letter-spacing: 3px; margin-bottom: 24px; text-transform: uppercase; }
    .points { display: grid; gap: 14px; }
    .point {
      background: rgba(240,192,96,0.06);
      border-right: 3px solid var(--gold);
      padding: 14px 18px;
      border-radius: 10px;
    }
    .point .pt-title { color: var(--gold); font-weight: 700; margin-bottom: 4px; }
    .point .pt-html { font-size: 15px; line-height: 1.6; opacity: 0.92; }
    .recap { margin-top: 26px; }
    .recap h3 { color: var(--teal); margin-bottom: 10px; font-size: 16px; }
    .chips { display: flex; flex-wrap: wrap; gap: 8px; }
    .chip {
      background: rgba(61,232,208,0.1);
      border: 1px solid rgba(61,232,208,0.3);
      color: var(--teal);
      padding: 6px 14px;
      border-radius: 50px;
      font-size: 14px;
    }
    .teaser {
      margin-top: 26px;
      text-align: center;
      color: var(--muted, #8880a0);
      font-size: 14px;
      font-style: italic;
    }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const points = Array.isArray(c.key_points) ? c.key_points : [];
    const recap = Array.isArray(c.vocabulary_recap) ? c.vocabulary_recap : [];
    return `
      <div class="wrap card">
        <div class="heading">סיכום השיעור</div>
        <div class="subhead">מה למדנו</div>
        <div class="points">
          ${points.map(p => `
            <div class="point">
              ${p.title ? `<div class="pt-title">${e(p.title)}</div>` : ""}
              <div class="pt-html">${p.html || ""}</div>
            </div>
          `).join("")}
        </div>
        ${recap.length ? `
          <div class="recap">
            <h3>אוצר המילים שלמדנו</h3>
            <div class="chips">${recap.map(w => `<span class="chip">${e(w)}</span>`).join("")}</div>
          </div>
        ` : ""}
        ${c.next_lesson_teaser ? `<div class="teaser">${e(c.next_lesson_teaser)}</div>` : ""}
      </div>
    `;
  }
}

customElements.define("slide-summary", SlideSummary);
