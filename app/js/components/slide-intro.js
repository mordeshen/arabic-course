import { BaseSlide } from "./base-slide.js";

class SlideIntro extends BaseSlide {
  static styles = `
    .wrap { text-align: center; padding: 40px 20px; }
    .ornament { color: var(--gold); font-size: 28px; letter-spacing: 12px; opacity: 0.6; margin-bottom: 24px; }
    .subtitle { color: var(--muted, #8880a0); font-size: 14px; letter-spacing: 4px; text-transform: uppercase; margin-bottom: 12px; }
    .title { color: var(--gold); font-size: clamp(36px, 7vw, 64px); font-weight: 900; margin-bottom: 18px; line-height: 1.1; }
    .arabic-title { font-family: 'Noto Naskh Arabic', serif; color: var(--teal); font-size: clamp(28px, 5vw, 44px); margin-bottom: 24px; }
    .desc { color: var(--text); font-size: 18px; line-height: 1.7; max-width: 640px; margin: 0 auto; opacity: 0.9; }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    return `
      <div class="wrap">
        ${c.ornament ? `<div class="ornament">${e(c.ornament)}</div>` : `<div class="ornament">✦ ✦ ✦</div>`}
        ${c.subtitle ? `<div class="subtitle">${e(c.subtitle)}</div>` : ""}
        ${c.title ? `<h1 class="title">${e(c.title)}</h1>` : ""}
        ${c.arabic_title ? `<div class="arabic-title">${e(c.arabic_title)}</div>` : ""}
        ${c.description ? `<p class="desc">${e(c.description)}</p>` : ""}
      </div>
    `;
  }
}

customElements.define("slide-intro", SlideIntro);
