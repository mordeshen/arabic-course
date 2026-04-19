import { BaseSlide } from "./base-slide.js";

class SlideQuizMatch extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .qs { display: grid; gap: 14px; margin-top: 18px; }
    .q {
      background: var(--card, rgba(255,255,255,0.04));
      border: 1px solid rgba(240,192,96,0.18);
      border-radius: 12px;
      padding: 18px;
    }
    .q .question { color: var(--text); font-size: 16px; margin-bottom: 12px; }
    .q .answer-wrap { display: none; margin-top: 10px; }
    .q.revealed .answer-wrap { display: block; animation: in 0.3s ease; }
    .q .answer { color: var(--teal); font-size: 16px; line-height: 1.6; }
    .q .hint { color: var(--muted, #8880a0); font-size: 13px; margin-top: 6px; font-style: italic; }
    .reveal-btn {
      background: rgba(240,192,96,0.12);
      border: 1px solid var(--gold);
      color: var(--gold);
      padding: 6px 18px;
      border-radius: 50px;
      cursor: pointer;
      font-family: 'Heebo', sans-serif;
      font-size: 13px;
      font-weight: 700;
    }
    .reveal-btn:hover { background: rgba(240,192,96,0.22); }
    .reveal-all {
      display: block;
      margin: 18px auto 0;
    }
    @keyframes in { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const qs = Array.isArray(c.questions) ? c.questions : [];
    return `
      <div class="wrap card">
        ${c.title ? `<div class="h-title">${e(c.title)}</div>` : `<div class="h-title">בדקו את עצמכם</div>`}
        <div class="qs">
          ${qs.map((q, i) => `
            <div class="q" data-i="${i}">
              <div class="question">${e(q.question)}</div>
              <button class="reveal-btn" type="button" data-i="${i}">חשוף תשובה</button>
              <div class="answer-wrap">
                <div class="answer">${e(q.answer)}</div>
                ${q.hint ? `<div class="hint">${e(q.hint)}</div>` : ""}
              </div>
            </div>
          `).join("")}
        </div>
        ${c.reveal_all_button !== false ? `<button class="reveal-btn reveal-all" type="button" id="reveal-all">חשוף הכל</button>` : ""}
      </div>
    `;
  }

  afterRender(_c, root) {
    root.querySelectorAll(".q .reveal-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        btn.closest(".q").classList.add("revealed");
        btn.style.display = "none";
      });
    });
    const all = root.querySelector("#reveal-all");
    if (all) {
      all.addEventListener("click", () => {
        root.querySelectorAll(".q").forEach(q => q.classList.add("revealed"));
        root.querySelectorAll(".q .reveal-btn").forEach(b => (b.style.display = "none"));
        all.style.display = "none";
      });
    }
  }
}

customElements.define("slide-quiz-match", SlideQuizMatch);
