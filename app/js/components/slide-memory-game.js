import { BaseSlide } from "./base-slide.js";

class SlideMemoryGame extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
    .timer { color: var(--teal); font-weight: 700; font-family: monospace; font-size: 18px; }
    .reset {
      background: rgba(240,192,96,0.12);
      border: 1px solid var(--gold);
      color: var(--gold);
      padding: 6px 16px;
      border-radius: 50px;
      cursor: pointer;
      font-family: 'Heebo', sans-serif;
      font-size: 13px;
      font-weight: 700;
    }
    .grid {
      display: grid;
      gap: 10px;
      grid-template-columns: repeat(4, 1fr);
    }
    @media (max-width: 520px) { .grid { grid-template-columns: repeat(3, 1fr); } }
    .tile {
      aspect-ratio: 1 / 1;
      background: linear-gradient(135deg, rgba(240,192,96,0.18), rgba(240,192,96,0.05));
      border: 1px solid rgba(240,192,96,0.35);
      border-radius: 12px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Noto Naskh Arabic', serif;
      font-size: 22px;
      color: transparent;
      user-select: none;
      transition: all 0.25s;
    }
    .tile.flipped { color: var(--gold); background: rgba(240,192,96,0.08); }
    .tile.matched { color: var(--teal); border-color: var(--teal); background: rgba(61,232,208,0.08); cursor: default; }
    .tile.he { font-family: 'Heebo', sans-serif; font-size: 16px; }
    .win { text-align: center; color: var(--teal); font-size: 18px; margin-top: 14px; min-height: 22px; }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const pairs = Array.isArray(c.pairs) ? c.pairs : [];
    return `
      <div class="wrap card">
        <div class="h-title">משחק זיכרון</div>
        <div class="meta">
          ${c.show_timer ? `<div class="timer" id="t">00:00</div>` : `<div></div>`}
          <button class="reset" type="button" id="reset">התחל מחדש</button>
        </div>
        <div class="grid" id="grid"></div>
        <div class="win" id="win"></div>
      </div>
    `;
  }

  afterRender(c, root) {
    const pairs = Array.isArray(c.pairs) ? c.pairs : [];
    const grid = root.getElementById("grid");
    const win = root.getElementById("win");
    const tEl = root.getElementById("t");
    let first = null, lock = false, matched = 0, t0 = null, timer = null;

    const startTimer = () => {
      if (!tEl) return;
      t0 = Date.now();
      timer = setInterval(() => {
        const s = Math.floor((Date.now() - t0) / 1000);
        tEl.textContent = `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
      }, 250);
    };
    const stopTimer = () => { if (timer) clearInterval(timer); timer = null; };

    const build = () => {
      grid.innerHTML = "";
      win.textContent = "";
      first = null; lock = false; matched = 0;
      stopTimer();
      if (tEl) tEl.textContent = "00:00";

      const cards = [];
      pairs.forEach((p, i) => {
        cards.push({ key: i, side: "ar", text: p.arabic });
        cards.push({ key: i, side: "he", text: p.hebrew });
      });
      cards.sort(() => Math.random() - 0.5);

      cards.forEach(card => {
        const el = document.createElement("div");
        el.className = "tile";
        if (card.side === "he") el.classList.add("he");
        el.dataset.key = card.key;
        el.textContent = card.text;
        el.addEventListener("click", () => {
          if (lock || el.classList.contains("flipped") || el.classList.contains("matched")) return;
          if (!t0) startTimer();
          el.classList.add("flipped");
          if (!first) { first = el; return; }
          if (first.dataset.key === el.dataset.key && first !== el) {
            first.classList.add("matched"); el.classList.add("matched");
            first = null; matched++;
            if (matched === pairs.length) {
              stopTimer();
              win.textContent = "🎉 כל הכבוד! מצאתם את כל הזוגות.";
            }
          } else {
            lock = true;
            setTimeout(() => {
              first.classList.remove("flipped");
              el.classList.remove("flipped");
              first = null; lock = false;
            }, 700);
          }
        });
        grid.appendChild(el);
      });
    };

    root.getElementById("reset").addEventListener("click", build);
    build();
  }
}

customElements.define("slide-memory-game", SlideMemoryGame);
