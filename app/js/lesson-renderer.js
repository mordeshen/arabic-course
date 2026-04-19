// ──────────────────────────────────────────────────────────────
// lesson-renderer.js
// Fetches lesson from /api/lessons/:num and generates the EXACT
// same HTML markup as the legacy static lessons. No Shadow DOM,
// no Web Components — just template functions + global CSS.
// ──────────────────────────────────────────────────────────────

import { getConfusionFeedback, getGenericFeedback } from "./letter-confusion-map.js";

const app = document.getElementById("app");
const nav = document.getElementById("nav");
const counter = document.getElementById("slideCounter");
const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const progressBar = document.getElementById("progressBar");

const params = new URLSearchParams(location.search);
const lessonId = parseInt(params.get("id"), 10);

if (!Number.isInteger(lessonId) || lessonId < 0) {
  showError("מספר שיעור לא תקין. <a href='/index.html'>חזרה לרשימת השיעורים</a>");
} else {
  loadLesson(lessonId);
}

// ── Fetch + render ──────────────────────────────────────────
async function loadLesson(num) {
  try {
    const res = await fetch(`/api/lessons/${num}`, { credentials: "include", headers: { Accept: "application/json" } });
    if (res.status === 401) return showError("צריך להתחבר כדי לגשת לשיעור הזה. <a href='/index.html'>חזרה</a>");
    if (res.status === 403) {
      const b = await safeJson(res);
      return showError((b?.message || "אין לך גישה.") + " <a href='/pricing.html?wanted=" + num + "'>לרכישה</a>");
    }
    if (!res.ok) return showError("שגיאה בטעינת השיעור (" + res.status + ").");
    const payload = await res.json();
    if (!payload?.lesson) return showError("השיעור לא נמצא.");
    document.title = `${payload.lesson.subtitle || "שיעור"} – ${payload.lesson.title}`;
    renderLesson(payload);
  } catch (e) {
    console.error(e);
    showError("שגיאת רשת. בדקו את החיבור.");
  }
}

function renderLesson({ lesson, slides }) {
  app.innerHTML = "";
  if (!Array.isArray(slides) || slides.length === 0) {
    return showError("השיעור הזה עדיין בהכנה. נחזור עם תוכן ממש בקרוב 🌙");
  }
  slides.forEach((slide, idx) => {
    const div = document.createElement("div");
    div.className = "slide" + (idx === 0 ? " active" : "");
    div.id = "s" + idx;
    const templateFn = TEMPLATES[slide.type];
    if (templateFn) {
      div.innerHTML = templateFn(slide.content || {}, lesson);
    } else {
      div.innerHTML = `<div class="state-msg">⚠ סוג שקופית לא נתמך: ${esc(slide.type)}</div>`;
    }
    app.appendChild(div);
  });

  // Attach behaviors after all slides are in the DOM
  attachBehaviors();
  initNavigation(slides.length);
}

// ── Navigation (identical to legacy) ────────────────────────
let currentSlide = 0, totalSlides = 0;
function initNavigation(count) {
  totalSlides = count;
  currentSlide = 0;
  nav.style.display = "";
  prevBtn.onclick = () => changeSlide(-1);
  nextBtn.onclick = () => changeSlide(1);
  document.addEventListener("keydown", e => {
    if (e.key === "ArrowLeft") changeSlide(1);
    if (e.key === "ArrowRight") changeSlide(-1);
  });
  updateNav();
}

function changeSlide(dir) {
  const slides = document.querySelectorAll(".slide");
  slides[currentSlide].classList.remove("active");
  currentSlide = Math.max(0, Math.min(totalSlides - 1, currentSlide + dir));
  slides[currentSlide].classList.add("active");
  window.scrollTo({ top: 0, behavior: "smooth" });
  updateNav();
}

function updateNav() {
  prevBtn.disabled = currentSlide === 0;
  if (currentSlide === totalSlides - 1) {
    const lessonNum = parseInt(document.title.match(/\d+/)?.[0] || "0");
    if (lessonNum > 0) {
      const completed = JSON.parse(localStorage.getItem("completedLessons") || "[]");
      if (!completed.includes(lessonNum)) { completed.push(lessonNum); localStorage.setItem("completedLessons", JSON.stringify(completed)); }
    }
    nextBtn.disabled = false;
    nextBtn.textContent = "← חזרה לקורס";
    nextBtn.onclick = () => { window.location.href = "/index.html"; };
  } else {
    nextBtn.disabled = false;
    nextBtn.textContent = "הבא ←";
    nextBtn.onclick = () => changeSlide(1);
  }
  counter.textContent = `${currentSlide + 1} / ${totalSlides}`;
  progressBar.style.width = `${((currentSlide + 1) / totalSlides) * 100}%`;
}

// ── Behavior attachment (after render) ──────────────────────
function attachBehaviors() {
  // Vocab cards — click to reveal
  document.querySelectorAll(".vocab-card").forEach(card => {
    card.addEventListener("click", () => {
      if (!card.classList.contains("revealed")) { card.classList.add("revealed"); spawnParticles(card); }
    });
  });
  // Example cards — click to reveal
  document.querySelectorAll(".example-card").forEach(card => {
    card.addEventListener("click", () => {
      if (!card.classList.contains("revealed")) {
        card.classList.add("revealed");
        const r = card.querySelector(".part-result");
        if (r) r.style.color = "var(--teal)";
        spawnParticles(card);
      }
    });
  });
  // Letter chips — toggle expand
  document.querySelectorAll(".letter-chip").forEach(chip => {
    chip.addEventListener("click", () => chip.classList.toggle("expanded"));
  });
  // Quiz answers — click to reveal
  document.querySelectorAll(".quiz-answer").forEach(el => {
    el.addEventListener("click", () => {
      if (!el.classList.contains("revealed")) { el.classList.add("revealed"); el.textContent = el.dataset.ans; spawnParticles(el); }
    });
  });
  // Reveal all buttons
  document.querySelectorAll(".reveal-all-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const slide = btn.closest(".slide");
      slide.querySelectorAll(".quiz-answer:not(.revealed)").forEach(el => { el.classList.add("revealed"); el.textContent = el.dataset.ans; });
    });
  });
  // Collision arenas — click to play
  document.querySelectorAll(".collision-arena").forEach(arena => {
    arena.addEventListener("click", () => runCollision(arena));
  });
  // Memory games — init
  document.querySelectorAll("[data-memory-pairs]").forEach(el => initMemory(el));
  // Drag letter games — init
  document.querySelectorAll("[data-drag-game]").forEach(el => initDragGame(el));
  // Letter trace canvases — init
  document.querySelectorAll(".trace-canvas[data-trace-letter]").forEach(el => initLetterTrace(el));
}

// ── Collision arena animation (same as legacy) ──────────────
function runCollision(arena) {
  if (arena.dataset.played) return;
  arena.dataset.played = "1";
  const stage = arena.querySelector(".collision-stage");
  const resultEl = arena.querySelector(".result-word");
  const labelEl = arena.querySelector(".result-label");
  const [left, , right] = stage.children;
  left.classList.add("collide-left");
  right.classList.add("collide-right");
  setTimeout(() => {
    left.classList.add("explode");
    right.classList.add("explode");
    spawnBigParticles(arena);
    setTimeout(() => {
      stage.style.display = "none";
      resultEl.style.display = "block";
      labelEl.style.display = "block";
      const h = arena.querySelector(".hint");
      if (h) h.style.display = "none";
    }, 450);
  }, 400);
}

// ── Memory game (same as legacy) ────────────────────────────
function initMemory(wrapper) {
  const pairs = JSON.parse(wrapper.dataset.memoryPairs);
  const grid = wrapper.querySelector(".memory-grid");
  const score = wrapper.querySelector(".memory-score");
  const timerEl = wrapper.querySelector(".memory-timer");
  let flipped = [], matched = 0, attempts = 0, seconds = 0, timer = null;

  function build() {
    grid.innerHTML = "";
    matched = 0; attempts = 0; seconds = 0; flipped = [];
    if (timer) clearInterval(timer);
    if (timerEl) timerEl.textContent = "⏱ 0:00";
    if (score) score.textContent = "";
    timer = setInterval(() => { seconds++; if (timerEl) timerEl.textContent = `⏱ ${Math.floor(seconds/60)}:${String(seconds%60).padStart(2,"0")}`; }, 1000);

    const cards = [];
    pairs.forEach(([a, h]) => { cards.push({ text: a, id: a }, { text: h, id: a }); });
    for (let i = cards.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [cards[i], cards[j]] = [cards[j], cards[i]]; }

    cards.forEach(c => {
      const d = document.createElement("div");
      d.className = "memory-card";
      d.dataset.id = c.id;
      d.textContent = c.text;
      d.addEventListener("click", () => flipCard(d));
      grid.appendChild(d);
    });
  }

  function flipCard(card) {
    if (card.classList.contains("flipped") || card.classList.contains("matched") || flipped.length >= 2) return;
    card.classList.add("flipped"); card.style.color = "var(--gold)";
    flipped.push(card);
    if (flipped.length === 2) {
      attempts++;
      if (flipped[0].dataset.id === flipped[1].dataset.id) {
        flipped.forEach(c => { c.classList.add("matched"); c.style.color = "var(--teal)"; });
        matched++; flipped = [];
        if (matched === pairs.length) {
          clearInterval(timer);
          const t = `${Math.floor(seconds/60)}:${String(seconds%60).padStart(2,"0")}`;
          if (score) score.innerHTML = `<span style="color:var(--teal)">🎉 כל הכבוד! ${attempts} ניסיונות, זמן: ${t}</span>`;
        }
      } else {
        setTimeout(() => { flipped.forEach(c => { c.classList.remove("flipped"); c.style.color = "transparent"; }); flipped = []; }, 800);
      }
    }
  }

  wrapper.querySelector(".memory-replay")?.addEventListener("click", build);
  build();
}

// ── Particle effects (same as legacy) ───────────────────────
function spawnParticles(card) {
  const colors = ["#f0c060","#3de8d0","#ff6b8a","#ffffff"];
  const rect = card.getBoundingClientRect();
  for (let i = 0; i < 8; i++) {
    const p = document.createElement("div");
    p.className = "particle";
    const angle = (i / 8) * Math.PI * 2;
    const dist = 30 + Math.random() * 40;
    p.style.cssText = `left:${rect.left+rect.width/2-3}px;top:${rect.top+rect.height/2-3}px;background:${colors[Math.floor(Math.random()*colors.length)]};position:fixed;--tx:${Math.cos(angle)*dist}px;--ty:${Math.sin(angle)*dist}px;z-index:9999;`;
    document.body.appendChild(p);
    setTimeout(() => p.remove(), 900);
  }
}

function spawnBigParticles(parent) {
  const colors = ["#f0c060","#3de8d0","#ff6b8a","#ffffff","#ffd97d"];
  const rect = parent.getBoundingClientRect();
  for (let i = 0; i < 20; i++) {
    const p = document.createElement("div");
    p.className = "particle";
    const angle = Math.random() * Math.PI * 2;
    const dist = 40 + Math.random() * 80;
    p.style.cssText = `left:${rect.left+rect.width/2-3+(Math.random()-0.5)*60}px;top:${rect.top+rect.height/2-3}px;background:${colors[Math.floor(Math.random()*colors.length)]};width:${4+Math.random()*6}px;height:${4+Math.random()*6}px;position:fixed;--tx:${Math.cos(angle)*dist}px;--ty:${Math.sin(angle)*dist}px;z-index:9999;animation-duration:${0.6+Math.random()*0.4}s;`;
    document.body.appendChild(p);
    setTimeout(() => p.remove(), 1100);
  }
}

// ── Helpers ─────────────────────────────────────────────────
function esc(s) { return String(s ?? "").replace(/[&<>"']/g, c => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c])); }
function showError(html) { app.innerHTML = `<div class="state-msg error">${html}</div>`; nav.style.display = "none"; }
async function safeJson(r) { try { return await r.json(); } catch { return null; } }

// ── Drag letter game ────────────────────────────────────────
function initDragGame(wrapper) {
  const challenges = JSON.parse(wrapper.dataset.dragGame);
  const wordDisplay = wrapper.querySelector(".drag-word-display");
  const feedback = wrapper.querySelector(".drag-feedback");
  const cardsRow = wrapper.querySelector(".drag-cards-row");
  const progress = wrapper.querySelector(".drag-progress");
  let currentIdx = 0, score = 0;

  function showChallenge(idx) {
    if (idx >= challenges.length) {
      wordDisplay.innerHTML = `<div style="font-size:48px;margin-bottom:10px;">🎉</div>`;
      feedback.innerHTML = `<span style="color:var(--teal);font-size:20px;font-weight:700;">כל הכבוד! ${score}/${challenges.length} נכון!</span>`;
      cardsRow.innerHTML = "";
      progress.textContent = "";
      return;
    }

    const ch = challenges[idx];
    progress.textContent = `${idx + 1} / ${challenges.length}`;
    feedback.innerHTML = "";

    // Show word with spaced letters, target slot highlighted
    wordDisplay.innerHTML = `
      <div style="margin-bottom:8px;color:var(--muted);font-size:13px;">${esc(ch.meaning || "")}</div>
      <div class="drag-word-letters">
        ${(ch.word_letters || []).map((l, i) => {
          const isTarget = i === ch.target_index;
          return `<span class="drag-letter-slot${isTarget ? " drag-target-slot" : ""}"
                   data-idx="${i}" data-char="${esc(l.char)}" data-name="${esc(l.name || "")}"
                   data-isolated="${esc(l.isolated || l.char)}">${isTarget ? "?" : esc(l.char)}</span>`;
        }).join("")}
      </div>
      <div style="margin-top:6px;color:var(--muted);font-size:13px;">${esc(ch.transliteration || "")}</div>
    `;

    // Build card options (shuffled)
    const options = [...(ch.options || [])];
    for (let i = options.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [options[i], options[j]] = [options[j], options[i]]; }
    cardsRow.innerHTML = options.map(opt => `
      <button class="drag-card" data-isolated="${esc(opt.isolated)}" data-name="${esc(opt.name)}">
        <span class="dc-letter">${esc(opt.isolated)}</span>
        <span class="dc-name">${esc(opt.name)}</span>
      </button>
    `).join("");

    // Click handler on cards
    cardsRow.querySelectorAll(".drag-card").forEach(card => {
      card.addEventListener("click", () => handleCardClick(card, ch, idx));
    });
  }

  function handleCardClick(card, ch, idx) {
    const picked = card.dataset.isolated;
    const correct = ch.correct_isolated;
    const slot = wordDisplay.querySelector(".drag-target-slot");

    if (picked === correct) {
      // Correct!
      score++;
      card.style.background = "rgba(61,232,208,0.2)";
      card.style.borderColor = "var(--teal)";
      card.style.color = "var(--teal)";
      if (slot) { slot.textContent = ch.word_letters[ch.target_index].char; slot.style.color = "var(--teal)"; slot.style.borderColor = "var(--teal)"; }
      feedback.innerHTML = `<span style="color:var(--teal);">✓ נכון! ${esc(ch.success_note || "")}</span>`;
      spawnParticles(card);
      setTimeout(() => { currentIdx++; showChallenge(currentIdx); }, 1400);
    } else {
      // Wrong — smart feedback
      card.style.background = "rgba(255,107,138,0.15)";
      card.style.borderColor = "var(--rose)";
      card.style.pointerEvents = "none";
      card.style.opacity = "0.5";

      const smartFb = getConfusionFeedback(correct, picked);
      if (smartFb) {
        feedback.innerHTML = `<span style="color:var(--rose);">${esc(smartFb)}</span>`;
      } else {
        feedback.innerHTML = `<span style="color:var(--rose);">${getGenericFeedback(ch.correct_name, card.dataset.name)}</span>`;
      }
    }
  }

  showChallenge(0);
}

// ── Letter tracing canvas ───────────────────────────────────
function initLetterTrace(visibleCanvas) {
  const wrap = visibleCanvas.closest(".letter-trace-wrap");
  if (!wrap || wrap.dataset.traceInit === "1") return;
  wrap.dataset.traceInit = "1";

  const letter = visibleCanvas.dataset.traceLetter;
  // Internal resolution (independent of display size).
  const W = 700, H = 450;
  const FONT_SIZE = 300;
  const FONT_FAMILY = "'Noto Naskh Arabic', serif";
  const TOLERANCE_PADDING = 55;
  const PEN_WIDTH = 28;
  const MIN_COVERAGE = 0.45;
  const MIN_PRECISION = 0.78;
  const MIN_USER_INK_RATIO = 0.18;

  visibleCanvas.width = W;
  visibleCanvas.height = H;
  const ctx = visibleCanvas.getContext("2d");

  const makeCanvas = () => { const c = document.createElement("canvas"); c.width = W; c.height = H; return c; };
  const guideCanvas = makeCanvas();
  const inkCanvas = makeCanvas();
  const targetCanvas = makeCanvas();
  const toleranceCanvas = makeCanvas();
  const guideCtx = guideCanvas.getContext("2d");
  const inkCtx = inkCanvas.getContext("2d");
  const targetCtx = targetCanvas.getContext("2d");
  const tolCtx = toleranceCanvas.getContext("2d");

  const clearBtn = wrap.querySelector(".trace-clear-btn");
  const feedback = wrap.querySelector(".trace-feedback");
  const progressEl = wrap.querySelector(".trace-progress");
  const timerEl = wrap.querySelector(".trace-timer");
  const timerArc = wrap.querySelector(".trace-timer-arc");
  const timerText = wrap.querySelector(".trace-timer-text");
  const REPS = Math.max(1, parseInt(wrap.dataset.traceReps || "4", 10));
  const TIMER_SECONDS = 6;
  const ARC_LEN = 2 * Math.PI * 22; // circumference for r=22
  let completedReps = 0;
  let timerId = null;
  let timerStartedAt = 0;
  function startTimer() {
    if (timerId) return;
    timerStartedAt = Date.now();
    if (timerEl) timerEl.hidden = false;
    if (timerArc) {
      timerArc.style.transition = "none";
      timerArc.style.strokeDasharray = `${ARC_LEN}`;
      timerArc.style.strokeDashoffset = "0";
      void timerArc.getBoundingClientRect();
      timerArc.style.transition = `stroke-dashoffset ${TIMER_SECONDS}s linear`;
      timerArc.style.strokeDashoffset = `${ARC_LEN}`;
    }
    if (timerText) timerText.textContent = String(TIMER_SECONDS);
    timerId = setInterval(() => {
      const elapsed = (Date.now() - timerStartedAt) / 1000;
      const remaining = Math.max(0, TIMER_SECONDS - elapsed);
      if (timerText) timerText.textContent = String(Math.ceil(remaining));
      if (remaining <= 0) {
        stopTimer();
        runCheck();
      }
    }, 120);
  }
  function stopTimer() {
    if (timerId) { clearInterval(timerId); timerId = null; }
    if (timerEl) timerEl.hidden = true;
    if (timerArc) {
      timerArc.style.transition = "none";
      timerArc.style.strokeDashoffset = "0";
    }
    if (timerText) timerText.textContent = String(TIMER_SECONDS);
  }
  function renderProgress(justFilledIdx) {
    if (!progressEl) return;
    progressEl.innerHTML =
      `<div class="trace-progress-label">התקדמות: ${completedReps} / ${REPS}</div>` +
      `<div class="trace-progress-track">` +
      Array.from({ length: REPS }, (_, i) => {
        const filled = i < completedReps ? " filled" : "";
        const pop = i === justFilledIdx ? " just-filled" : "";
        return `<span class="trace-segment${filled}${pop}"></span>`;
      }).join("") +
      `</div>`;
  }
  renderProgress();
  function clearInk() {
    inkCtx.clearRect(0, 0, W, H);
    repaint();
  }

  function buildMasks() {
    targetCtx.clearRect(0, 0, W, H);
    targetCtx.fillStyle = "#000";
    targetCtx.font = `${FONT_SIZE}px ${FONT_FAMILY}`;
    targetCtx.textAlign = "center";
    targetCtx.textBaseline = "middle";
    targetCtx.fillText(letter, W/2, H/2);

    tolCtx.clearRect(0, 0, W, H);
    tolCtx.strokeStyle = "#000";
    tolCtx.fillStyle = "#000";
    tolCtx.lineWidth = TOLERANCE_PADDING * 2;
    tolCtx.lineJoin = "round";
    tolCtx.lineCap = "round";
    tolCtx.font = `${FONT_SIZE}px ${FONT_FAMILY}`;
    tolCtx.textAlign = "center";
    tolCtx.textBaseline = "middle";
    tolCtx.strokeText(letter, W/2, H/2);
    tolCtx.fillText(letter, W/2, H/2);
  }

  function buildGuide() {
    guideCtx.clearRect(0, 0, W, H);
    guideCtx.strokeStyle = "rgba(90, 90, 110, 0.35)";
    guideCtx.setLineDash([7, 7]);
    guideCtx.lineWidth = 1.2;
    const margin = 24;
    [H * 0.22, H * 0.5, H * 0.78].forEach(y => {
      guideCtx.beginPath(); guideCtx.moveTo(margin, y); guideCtx.lineTo(W - margin, y); guideCtx.stroke();
    });
    guideCtx.setLineDash([]);
    guideCtx.fillStyle = "rgba(50, 50, 80, 0.18)";
    guideCtx.font = `${FONT_SIZE}px ${FONT_FAMILY}`;
    guideCtx.textAlign = "center";
    guideCtx.textBaseline = "middle";
    guideCtx.fillText(letter, W/2, H/2);
    guideCtx.save();
    guideCtx.setLineDash([6, 5]);
    guideCtx.strokeStyle = "rgba(120, 120, 160, 0.55)";
    guideCtx.lineWidth = 1.4;
    guideCtx.strokeText(letter, W/2, H/2);
    guideCtx.restore();
  }

  function repaint() {
    ctx.clearRect(0, 0, W, H);
    ctx.drawImage(guideCanvas, 0, 0);
    ctx.drawImage(inkCanvas, 0, 0);
  }

  let drawing = false, lastX = 0, lastY = 0;
  function canvasCoords(e) {
    const rect = visibleCanvas.getBoundingClientRect();
    const cx = e.clientX ?? (e.touches && e.touches[0]?.clientX);
    const cy = e.clientY ?? (e.touches && e.touches[0]?.clientY);
    return { x: (cx - rect.left) * (W / rect.width), y: (cy - rect.top) * (H / rect.height) };
  }
  function startDraw(e) {
    e.preventDefault(); drawing = true;
    startTimer();
    const { x, y } = canvasCoords(e); lastX = x; lastY = y;
    inkCtx.fillStyle = "#d08020";
    inkCtx.beginPath(); inkCtx.arc(x, y, PEN_WIDTH / 2, 0, Math.PI * 2); inkCtx.fill();
    repaint();
  }
  function moveDraw(e) {
    if (!drawing) return;
    e.preventDefault();
    const { x, y } = canvasCoords(e);
    inkCtx.strokeStyle = "#d08020";
    inkCtx.lineWidth = PEN_WIDTH;
    inkCtx.lineCap = "round";
    inkCtx.lineJoin = "round";
    inkCtx.beginPath(); inkCtx.moveTo(lastX, lastY); inkCtx.lineTo(x, y); inkCtx.stroke();
    lastX = x; lastY = y;
    repaint();
  }
  function endDraw() { drawing = false; }

  visibleCanvas.addEventListener("pointerdown", startDraw);
  visibleCanvas.addEventListener("pointermove", moveDraw);
  window.addEventListener("pointerup", endDraw);
  visibleCanvas.addEventListener("pointercancel", endDraw);

  clearBtn?.addEventListener("click", () => {
    clearInk();
    stopTimer();
    feedback.className = "trace-feedback";
    feedback.textContent = 'ציירו את האות בתוך המסגרת. הבדיקה תתבצע אוטומטית אחרי 6 שניות.';
  });

  function computeScores() {
    const t = targetCtx.getImageData(0, 0, W, H).data;
    const to = tolCtx.getImageData(0, 0, W, H).data;
    const u = inkCtx.getImageData(0, 0, W, H).data;
    let userPixels = 0, userInsideTolerance = 0, targetPixels = 0, targetCovered = 0;
    for (let i = 0; i < u.length; i += 4) {
      const userInk = u[i + 3] > 30;
      const inTarget = t[i + 3] > 30;
      const inTol = to[i + 3] > 30;
      if (userInk) { userPixels++; if (inTol) userInsideTolerance++; }
      if (inTarget) { targetPixels++; if (userInk) targetCovered++; }
    }
    return {
      coverage: targetPixels ? targetCovered / targetPixels : 0,
      precision: userPixels ? userInsideTolerance / userPixels : 0,
      inkRatio: targetPixels ? userPixels / targetPixels : 0,
      userPixels
    };
  }

  function runCheck() {
    stopTimer();
    const s = computeScores();
    const metrics = `<span class="trace-metrics">כיסוי ${(s.coverage*100).toFixed(0)}% · דיוק ${(s.precision*100).toFixed(0)}% · דיו ${(s.inkRatio*100).toFixed(0)}%</span>`;
    if (s.userPixels === 0) {
      feedback.className = "trace-feedback error";
      feedback.innerHTML = `עוד לא ציירתם 🙂${metrics}`; return;
    }
    if (s.inkRatio < MIN_USER_INK_RATIO) {
      feedback.className = "trace-feedback error";
      feedback.innerHTML = `נסו לצייר את כל האות — עוד לא סיימתם.${metrics}`; return;
    }
    if (s.precision < MIN_PRECISION) {
      feedback.className = "trace-feedback error";
      feedback.innerHTML = `חרגתם מהמסגרת. נסו שוב — עקבו אחרי קווי המתאר של האות.${metrics}`; return;
    }
    if (s.coverage < MIN_COVERAGE) {
      feedback.className = "trace-feedback error";
      feedback.innerHTML = `כתבתם בתוך הקווים, אבל לא כיסיתם מספיק מהאות. נסו לעבות את הקו.${metrics}`; return;
    }
    completedReps = Math.min(REPS, completedReps + 1);
    renderProgress(completedReps - 1);
    celebrate(completedReps === REPS);
    if (completedReps < REPS) {
      feedback.className = "trace-feedback success";
      feedback.innerHTML = `יפה! תרגול ${completedReps} מתוך ${REPS}. נסו שוב כדי לחזק את הזיכרון.${metrics}`;
      setTimeout(() => {
        clearInk();
        feedback.className = "trace-feedback";
        feedback.textContent = `תרגול ${completedReps + 1} מתוך ${REPS} — ציירו את האות שוב.`;
      }, 1800);
    } else {
      feedback.className = "trace-feedback success final";
      feedback.innerHTML = `🎉 כל הכבוד! השלמתם ${REPS} תרגולים ✓ האות הזו כבר שלכם.${metrics}`;
    }
  }

  function celebrate(isFinal) {
    const frame = wrap.querySelector(".trace-frame");
    if (frame) {
      frame.classList.remove("celebrate");
      void frame.offsetWidth; // restart animation
      frame.classList.add("celebrate");
      setTimeout(() => frame.classList.remove("celebrate"), 700);
    }
    spawnBigParticles(visibleCanvas);
    if (isFinal) {
      setTimeout(() => spawnBigParticles(visibleCanvas), 180);
      setTimeout(() => spawnBigParticles(visibleCanvas), 360);
    }
  }

  function init() {
    buildMasks();
    buildGuide();
    repaint();
  }
  init();
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(init);
  } else {
    setTimeout(init, 400);
  }
}

// ══════════════════════════════════════════════════════════════
// TEMPLATE FUNCTIONS — generate the EXACT same HTML as legacy
// ══════════════════════════════════════════════════════════════

const TEMPLATES = {
  // ── intro ──
  intro(c) {
    return `
      <div class="title-slide">
        <div class="subtitle">${esc(c.subtitle || "")}</div>
        <h1>${esc(c.title || "")}</h1>
        <div class="arabic-title">${esc(c.arabic_title || "")}</div>
        <div class="ornament">${esc(c.ornament || "✦ ✧ ✦")}</div>
        <div class="desc">${esc(c.description || "")}</div>
      </div>`;
  },

  // ── rule_card ──
  rule_card(c) {
    const examples = Array.isArray(c.examples) ? c.examples : [];
    const exHtml = examples.length ? `
      <div class="separator-line"></div>
      ${examples.map(ex => `
        <div style="text-align:center;margin-bottom:12px;">
          <span style="font-family:'Noto Naskh Arabic',serif;font-size:26px;color:var(--teal);">${esc(ex.arabic)}</span><br>
          <span style="color:var(--text);font-size:15px;">${esc(ex.hebrew)}</span>
        </div>
      `).join("")}
    ` : "";
    return `
      <div class="slide-inner">
        ${c.title ? `<div class="section-header"><div class="section-tag">כלל</div><h2>${esc(c.title)}</h2></div>` : ""}
        <div class="rule-card">
          <p class="rule-text">${c.html || ""}</p>
        </div>
        ${exHtml}
      </div>`;
  },

  // ── collision_arena ──
  collision_arena(c) {
    return `
      <div class="slide-inner">
        <div class="collision-arena">
          <div class="collision-stage">
            <div class="word-bubble">${esc(c.left_word)}</div>
            <div class="plus-sign">${esc(c.operator || "+")}</div>
            <div class="word-bubble teal-bubble">${esc(c.right_word)}</div>
          </div>
          <div class="result-word">${esc(c.result)}</div>
          <div class="result-label">${esc(c.result_label)}</div>
          <div class="hint">▶ לחצו להדגמה</div>
        </div>
      </div>`;
  },

  // ── letter_chips ──
  letter_chips(c) {
    const groups = Array.isArray(c.groups) ? c.groups : [];
    const colorMap = { gold: "chip-gold", rose: "chip-rose", teal: "chip-teal" };
    const colorStyle = { gold: "color: var(--gold);", rose: "color: var(--rose);", teal: "color: var(--teal);" };
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">אותיות</div>
          <h2>לחצו על כל אות לדוגמה</h2>
        </div>
        ${groups.map(g => `
          <div class="letter-group">
            <h3 style="${colorStyle[g.color] || ""}">${esc(g.title)}</h3>
            <div class="letters-row">
              ${(g.letters || []).map(l => `
                <span class="letter-chip ${colorMap[g.color] || "chip-gold"}">${esc(l.letter)}<span class="chip-example">${esc(l.example)}</span></span>
              `).join("")}
            </div>
            ${g.note ? `<div style="font-size:12px;color:var(--muted);margin-top:8px;padding-right:4px;">${esc(g.note)}</div>` : ""}
          </div>
        `).join("")}
      </div>`;
  },

  // ── vocab_grid ──
  vocab_grid(c) {
    const items = Array.isArray(c.items) ? c.items : [];
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">אוצר מילים</div>
          <h2>${esc(c.title || "")}</h2>
        </div>
        <div class="vocab-grid">
          ${items.map(it => `
            <div class="vocab-card">
              <div class="click-hint">לחץ</div>
              <div class="vocab-arabic">${esc(it.arabic)}</div>
              <div class="vocab-hebrew">${esc(it.hebrew)}</div>
            </div>
          `).join("")}
        </div>
      </div>`;
  },

  // ── example_cards ──
  example_cards(c) {
    const items = Array.isArray(c.items) ? c.items : [];
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">דוגמאות</div>
          <h2>${esc(c.title || "מילים לכל קבוצה")}</h2>
        </div>
        <div class="examples-grid">
          ${items.map(it => `
            <div class="example-card">
              <div class="click-hint">לחץ</div>
              <div class="parts">
                <span class="part-word">${esc(it.arabic_phrase)}</span>
                <span class="part-sep">${esc(it.separator || "=")}</span>
                <span class="part-result">${esc(it.hebrew_translation)}</span>
              </div>
              <div class="translation">${esc(it.translation_note || "")}</div>
            </div>
          `).join("")}
        </div>
      </div>`;
  },

  // ── quiz_match ──
  quiz_match(c) {
    const questions = Array.isArray(c.questions) ? c.questions : [];
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">תרגול</div>
          <h2>${esc(c.title || "בדקו את עצמכם")}</h2>
        </div>
        ${c.reveal_all_button !== false ? `<button class="reveal-all-btn">גלה הכל</button>` : ""}
        ${questions.map(q => `
          <div class="quiz-question">
            <div class="quiz-q-text">${esc(q.question)}</div>
            <div class="quiz-words">
              <span class="quiz-word">${esc(q.question.split("?")[0]?.split(" ").pop() || "")}</span>
              <span class="quiz-arrow">←</span>
              <span class="quiz-answer" data-ans="${esc(q.answer)}">?</span>
            </div>
            ${q.hint ? `<div class="quiz-hint">${esc(q.hint)}</div>` : ""}
          </div>
        `).join("")}
      </div>`;
  },

  // ── memory_game ──
  memory_game(c) {
    const pairs = Array.isArray(c.pairs) ? c.pairs : [];
    const pairsJson = JSON.stringify(pairs.map(p => [p.arabic, p.hebrew]));
    return `
      <div class="slide-inner" data-memory-pairs='${esc(pairsJson)}'>
        <div class="section-header">
          <div class="section-tag">משחק</div>
          <h2>משחק זיכרון</h2>
        </div>
        <p style="color:var(--muted);text-align:center;margin-bottom:16px;font-size:13px;">מצאו את הזוגות — מילה ותרגום</p>
        <div class="memory-grid"></div>
        <div class="memory-timer" style="text-align:center;color:var(--muted);font-size:13px;margin-top:8px;">⏱ 0:00</div>
        <div class="memory-score" style="text-align:center;margin-top:14px;color:var(--gold);font-size:14px;"></div>
        <button class="memory-replay" style="display:block;margin:12px auto 0;background:rgba(61,232,208,0.1);border:1px solid var(--teal);color:var(--teal);padding:8px 20px;border-radius:8px;cursor:pointer;font-family:'Heebo',sans-serif;font-size:13px;">שחק שוב</button>
      </div>`;
  },

  // ── summary ──
  summary(c) {
    const points = Array.isArray(c.key_points) ? c.key_points : [];
    const recap = Array.isArray(c.vocabulary_recap) ? c.vocabulary_recap : [];
    return `
      <div class="slide-inner summary-section">
        <div class="section-header">
          <div class="section-tag">סיכום</div>
          <h2>מה למדנו</h2>
        </div>
        ${points.map(p => `
          <div class="rule-card">
            <p class="rule-text">
              ${p.title ? `<span class="highlight">${p.title}</span><br>` : ""}
              ${p.html || ""}
            </p>
          </div>
          <div class="separator-line"></div>
        `).join("")}
        ${c.next_lesson_teaser ? `
          <div class="rule-card" style="text-align:center; border-right: none; border-top: 4px solid var(--teal);">
            <p class="rule-text" style="text-align:center">${esc(c.next_lesson_teaser)}</p>
          </div>
        ` : ""}
        <div class="celebration">
          <div style="font-size:48px; margin-bottom:10px;">🎉</div>
          <div style="color: var(--gold); font-family: 'Noto Serif Hebrew', serif; font-size: 24px; font-weight:700; margin-bottom:8px;">כל הכבוד! סיימת את השיעור!</div>
          <a href="/index.html" style="display:inline-block; background: linear-gradient(135deg, var(--gold), #e0a030); color: #0a0a14; padding: 12px 30px; border-radius: 50px; text-decoration: none; font-weight: 700; font-size: 15px;">← חזרה לדף הקורס</a>
        </div>
      </div>`;
  },

  // ── letter_identify — highlight target letter in words ──
  letter_identify(c) {
    const examples = Array.isArray(c.examples) ? c.examples : [];
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">זיהוי</div>
          <h2>${esc(c.title || "מצאו את האות במילה")}</h2>
        </div>
        ${c.intro ? `<div class="rule-card"><p class="rule-text">${c.intro}</p></div>` : ""}
        <div class="letter-identify-grid">
          ${examples.map(ex => `
            <div class="li-word-card">
              <div class="li-position-tag">${esc(ex.position_label || "")}</div>
              <div class="li-word">
                ${(ex.letters || []).map(l =>
                  `<span class="li-letter${l.highlight ? " li-highlight" : ""}" title="${esc(l.name || "")}">${esc(l.char)}</span>`
                ).join("")}
              </div>
              <div class="li-transliteration">${esc(ex.transliteration || "")}</div>
              <div class="li-meaning">${esc(ex.meaning || "")}</div>
            </div>
          `).join("")}
        </div>
        ${c.note ? `<div class="rule-card" style="margin-top:16px;border-right-color:var(--teal);"><p class="rule-text">${c.note}</p></div>` : ""}
      </div>`;
  },

  // ── letter_drag_game — drag cards to match letters in words ──
  letter_drag_game(c) {
    const challenges = Array.isArray(c.challenges) ? c.challenges : [];
    const challengeJson = JSON.stringify(challenges);
    return `
      <div class="slide-inner" data-drag-game='${esc(challengeJson)}'>
        <div class="section-header">
          <div class="section-tag">משחק</div>
          <h2>${esc(c.title || "זהו את האותיות!")}</h2>
        </div>
        ${c.instructions ? `<p style="color:var(--muted);text-align:center;margin-bottom:16px;font-size:13px;">${esc(c.instructions)}</p>` : ""}
        <div class="drag-game-area">
          <div class="drag-word-display"></div>
          <div class="drag-feedback" style="min-height:50px;text-align:center;margin:16px 0;font-size:15px;line-height:1.6;"></div>
          <div class="drag-cards-row"></div>
          <div class="drag-progress" style="text-align:center;margin-top:14px;color:var(--muted);font-size:13px;"></div>
        </div>
      </div>`;
  },

  // ── letter_trace — trace the letter inside a framed "notebook" ──
  letter_trace(c) {
    const letter = c.letter || "";
    const title = c.title || `כתבו את האות ${letter}`;
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">תרגול כתיבה</div>
          <h2>${esc(title)}</h2>
        </div>
        ${c.intro ? `<div class="rule-card" style="margin-bottom:16px;"><p class="rule-text">${c.intro}</p></div>` : ""}
        <div class="letter-trace-wrap" data-trace-reps="${esc(c.repetitions || 4)}">
          <div class="lt-info">
            <div class="lt-letter">${esc(letter)}</div>
            <div class="lt-labels">
              ${c.letter_hebrew_name ? `<div>שם: <b class="teal">${esc(c.letter_hebrew_name)}</b></div>` : ""}
              ${c.sound ? `<div>צליל: <b class="teal">${esc(c.sound)}</b></div>` : ""}
            </div>
          </div>
          <div class="trace-progress"></div>
          <div class="trace-frame">
            <canvas class="trace-canvas" data-trace-letter="${esc(letter)}"></canvas>
            <button class="trace-clear-btn" type="button" aria-label="נקה ציור" title="נקה ציור">↻</button>
            <div class="trace-timer" hidden>
              <svg viewBox="0 0 50 50" aria-hidden="true">
                <circle class="trace-timer-track" cx="25" cy="25" r="22"></circle>
                <circle class="trace-timer-arc"   cx="25" cy="25" r="22"></circle>
              </svg>
              <div class="trace-timer-text">6</div>
            </div>
          </div>
          <div class="trace-feedback">ציירו את האות בתוך המסגרת. הבדיקה תתבצע אוטומטית אחרי 6 שניות.</div>
        </div>
        ${c.note ? `<div class="rule-card" style="margin-top:16px;border-right-color:var(--teal);"><p class="rule-text">${c.note}</p></div>` : ""}
      </div>`;
  },

  // ── letter_forms_table ──
  letter_forms_table(c) {
    const rows = Array.isArray(c.rows) ? c.rows : [];
    return `
      <div class="slide-inner">
        <div class="section-header">
          <div class="section-tag">אותיות</div>
          <h2>${esc(c.title || "צורות האותיות")}</h2>
        </div>
        <div class="rule-card" style="border-right-color:var(--teal);margin-bottom:16px;">
          <p class="rule-text" style="text-align:center;">
            <span class="teal">אל תיבהלו מהכמות!</span> זו טבלת עזר — נעבוד עליה <span class="highlight">כל פעם כמה אותיות</span>, לאט ובנוחות.<br>
            מומלץ <span class="highlight">להדפיס את הטבלה</span> ולשים אותה ליד המחשב כדי שתוכלו להסתכל בכל עת.
          </p>
        </div>
        <button class="print-btn" onclick="window.print()">🖨️ הדפסת הטבלה</button>
        ${c.intro_html ? `<div class="rule-card"><p class="rule-text">${c.intro_html}</p></div>` : ""}
        <div class="letter-forms-table">
          <table>
            <thead>
              <tr>
                <th>שם</th>
                <th>צליל</th>
                <th>עצמאית</th>
                <th>תחילת מילה</th>
                <th>אמצע מילה</th>
                <th>סוף מילה</th>
                <th>דוגמה</th>
              </tr>
            </thead>
            <tbody>
              ${rows.map(r => {
                const xBadge = r.non_connector
                  ? '<span class="non-connect-x" title="לא מתחברת לאות הבאה">✕</span>'
                  : "";
                return `
                <tr${r.non_connector ? ' class="non-connect-row"' : ""}>
                  <td class="he-name">${esc(r.hebrew_name)}${xBadge}</td>
                  <td class="sound">${esc(r.sound)}</td>
                  <td class="ar">${esc(r.isolated)}</td>
                  <td class="ar-form">${esc(r.initial)}</td>
                  <td class="ar-form">${esc(r.medial)}</td>
                  <td class="ar-form">${esc(r.final)}</td>
                  <td>
                    <span class="ex-ar">${esc(r.example_arabic)}</span><br>
                    <span class="ex-he">${esc(r.example_hebrew)}</span>
                  </td>
                </tr>
              `;
              }).join("")}
            </tbody>
          </table>
        </div>
        ${c.note ? `<div class="rule-card" style="margin-top:14px;border-right-color:var(--teal);"><p class="rule-text">${c.note}</p></div>` : ""}
      </div>`;
  },
};
