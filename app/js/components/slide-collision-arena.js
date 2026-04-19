import { BaseSlide } from "./base-slide.js";

class SlideCollisionArena extends BaseSlide {
  static styles = `
    .arena {
      padding: 50px 20px;
      text-align: center;
      min-height: 320px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 22px;
    }
    .row { display: flex; align-items: center; justify-content: center; gap: 24px; flex-wrap: wrap; }
    .word {
      font-family: 'Noto Naskh Arabic', serif;
      font-size: clamp(40px, 7vw, 64px);
      font-weight: 700;
      color: var(--gold);
      transition: transform 0.7s ease;
    }
    .op { font-size: 36px; color: var(--rose); }
    .result {
      font-family: 'Noto Naskh Arabic', serif;
      font-size: clamp(48px, 8vw, 72px);
      font-weight: 900;
      color: var(--teal);
      opacity: 0;
      transform: scale(0.5);
      transition: all 0.6s ease;
    }
    .result.show { opacity: 1; transform: scale(1); }
    .result-label { color: var(--muted, #8880a0); font-size: 18px; opacity: 0; transition: opacity 0.5s 0.3s; }
    .result-label.show { opacity: 1; }
    .replay {
      margin-top: 14px;
      background: rgba(240,192,96,0.12);
      border: 1px solid var(--gold);
      color: var(--gold);
      padding: 8px 22px;
      border-radius: 50px;
      cursor: pointer;
      font-family: 'Heebo', sans-serif;
      font-weight: 700;
      font-size: 13px;
    }
    .replay:hover { background: rgba(240,192,96,0.22); }
    .colliding .left  { transform: translateX(40px); }
    .colliding .right { transform: translateX(-40px); }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    return `
      <div class="card arena">
        <div class="row collide-row">
          <div class="word left">${e(c.left_word)}</div>
          <div class="op">${e(c.operator || "+")}</div>
          <div class="word right">${e(c.right_word)}</div>
        </div>
        <div class="result">${e(c.result)}</div>
        <div class="result-label">${e(c.result_label)}</div>
        <button class="replay" type="button">▷ הפעל שוב</button>
      </div>
    `;
  }

  afterRender(_c, root) {
    const row = root.querySelector(".collide-row");
    const result = root.querySelector(".result");
    const label = root.querySelector(".result-label");
    const replay = root.querySelector(".replay");

    const play = () => {
      row.classList.remove("colliding");
      result.classList.remove("show");
      label.classList.remove("show");
      // restart animation
      void row.offsetWidth;
      setTimeout(() => row.classList.add("colliding"), 300);
      setTimeout(() => {
        result.classList.add("show");
        label.classList.add("show");
      }, 1100);
    };

    replay.addEventListener("click", play);
    setTimeout(play, 250);
  }
}

customElements.define("slide-collision-arena", SlideCollisionArena);
