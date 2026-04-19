import { BaseSlide } from "./base-slide.js";

// letter_chips — used by lesson 1 (אותיות הא"ב). Groups of clickable chips,
// each chip flips to reveal an Arabic example.
class SlideLetterChips extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .group {
      background: var(--card, rgba(255,255,255,0.04));
      border-radius: 14px;
      padding: 16px 18px;
      margin: 14px 0;
      border: 1px solid rgba(240,192,96,0.18);
    }
    .group.gold  { border-color: rgba(240,192,96,0.45); }
    .group.teal  { border-color: rgba(61,232,208,0.45); }
    .group.rose  { border-color: rgba(255,107,138,0.45); }
    .group-title { font-weight: 700; margin-bottom: 12px; font-size: 16px; }
    .group.gold .group-title { color: var(--gold); }
    .group.teal .group-title { color: var(--teal); }
    .group.rose .group-title { color: var(--rose); }
    .chips { display: flex; flex-wrap: wrap; gap: 8px; }
    .chip {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 12px;
      padding: 10px 14px;
      cursor: pointer;
      min-width: 64px;
      text-align: center;
      font-weight: 700;
      font-size: 18px;
      transition: all 0.2s;
      user-select: none;
    }
    .chip:hover { transform: translateY(-2px); }
    .chip.flipped {
      font-family: 'Heebo', sans-serif;
      color: var(--gold);
      background: rgba(240,192,96,0.1);
      border-color: var(--gold);
      font-size: 13px;
      padding: 10px 12px;
      min-width: 120px;
      line-height: 1.4;
    }
    .group-note {
      margin-top: 10px;
      font-size: 12px;
      color: var(--muted, #8880a0);
      padding-right: 4px;
    }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const groups = Array.isArray(c.groups) ? c.groups : [];
    return `
      <div class="wrap card">
        <div class="h-title">אותיות הא"ב</div>
        ${groups.map(g => `
          <div class="group ${e(g.color || "gold")}">
            <div class="group-title">${e(g.title)}</div>
            <div class="chips">
              ${(g.letters || []).map(l => `
                <div class="chip" data-front="${e(l.letter)}" data-back="${e(l.example)}">${e(l.letter)}</div>
              `).join("")}
            </div>
            ${g.note ? `<div class="group-note">${e(g.note)}</div>` : ""}
          </div>
        `).join("")}
      </div>
    `;
  }

  afterRender(_c, root) {
    root.querySelectorAll(".chip").forEach(el => {
      el.addEventListener("click", () => {
        const flipped = el.classList.toggle("flipped");
        el.textContent = flipped ? el.dataset.back : el.dataset.front;
      });
    });
  }
}

customElements.define("slide-letter-chips", SlideLetterChips);
