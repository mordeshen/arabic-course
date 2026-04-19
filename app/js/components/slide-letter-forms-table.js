import { BaseSlide } from "./base-slide.js";

// letter_forms_table — Arabic alphabet contextual forms.
// Each row shows: Hebrew name, sound, isolated, initial, medial, final, + example.
// Designed to be readable on mobile (rows scroll horizontally if needed).
class SlideLetterFormsTable extends BaseSlide {
  static styles = `
    .wrap { padding: 14px 0; }
    .intro { color: var(--text); line-height: 1.7; margin-bottom: 14px; opacity: 0.9; }
    .table-scroll {
      overflow-x: auto;
      -webkit-overflow-scrolling: touch;
      border-radius: 12px;
      border: 1px solid rgba(240,192,96,0.2);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      direction: rtl;
      min-width: 640px;
    }
    thead th {
      background: rgba(240,192,96,0.12);
      color: var(--gold);
      font-size: 13px;
      font-weight: 700;
      padding: 12px 8px;
      text-align: center;
      border-bottom: 1px solid rgba(240,192,96,0.3);
      white-space: nowrap;
    }
    tbody td {
      padding: 12px 8px;
      text-align: center;
      border-bottom: 1px solid rgba(255,255,255,0.06);
      vertical-align: middle;
    }
    tbody tr:hover { background: rgba(240,192,96,0.04); }
    tbody tr:nth-child(odd) { background: rgba(255,255,255,0.015); }
    .he-name { color: var(--text); font-weight: 700; font-size: 15px; }
    .sound   { color: var(--muted, #8880a0); font-size: 13px; font-style: italic; }
    .ar      { font-family: 'Noto Naskh Arabic', serif; color: var(--gold); font-size: 26px; line-height: 1; }
    .ar-final, .ar-medial, .ar-initial { color: var(--teal); }
    .ex {
      display: flex;
      flex-direction: column;
      gap: 2px;
      align-items: center;
    }
    .ex-ar { font-family: 'Noto Naskh Arabic', serif; color: var(--gold); font-size: 20px; }
    .ex-he { color: var(--text); font-size: 12px; opacity: 0.8; }
    .note {
      margin-top: 14px;
      padding: 12px 14px;
      background: rgba(61,232,208,0.06);
      border-right: 3px solid var(--teal);
      border-radius: 8px;
      font-size: 13px;
      color: var(--text);
      line-height: 1.6;
    }
    .non-connector td.ar-medial::after,
    .non-connector td.ar-initial::after {
      content: ' ✕';
      font-size: 11px;
      color: var(--rose);
      opacity: 0.6;
    }
  `;

  static template(c) {
    const e = BaseSlide.esc;
    const rows = Array.isArray(c.rows) ? c.rows : [];
    return `
      <div class="wrap card">
        ${c.title ? `<div class="h-title">${e(c.title)}</div>` : ""}
        ${c.intro_html ? `<div class="intro">${c.intro_html}</div>` : ""}
        <div class="table-scroll">
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
              ${rows.map(r => `
                <tr class="${r.non_connector ? "non-connector" : ""}">
                  <td class="he-name">${e(r.hebrew_name)}</td>
                  <td class="sound">${e(r.sound)}</td>
                  <td class="ar">${e(r.isolated)}</td>
                  <td class="ar ar-initial">${e(r.initial)}</td>
                  <td class="ar ar-medial">${e(r.medial)}</td>
                  <td class="ar ar-final">${e(r.final)}</td>
                  <td>
                    <div class="ex">
                      <span class="ex-ar">${e(r.example_arabic)}</span>
                      <span class="ex-he">${e(r.example_hebrew)}</span>
                    </div>
                  </td>
                </tr>
              `).join("")}
            </tbody>
          </table>
        </div>
        ${c.note ? `<div class="note">${c.note}</div>` : ""}
      </div>
    `;
  }
}

customElements.define("slide-letter-forms-table", SlideLetterFormsTable);
