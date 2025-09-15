// Zoek een specifiek vers
const verseForm = document.getElementById('verseForm');
const verseResult = document.getElementById('verseResult');
verseForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    verseResult.textContent = 'Bezig met zoeken...';
    const book = document.getElementById('book').value;
    const chapter = document.getElementById('chapter').value;
    const verse = document.getElementById('verse').value;
    try {
        const res = await fetch(`/api/verse?book=${encodeURIComponent(book)}&chapter=${chapter}&verse=${verse}`);
        if (!res.ok) throw new Error('Niet gevonden of fout in API');
        const data = await res.json();
        verseResult.innerHTML = `<b>${data.book} ${data.chapter}:${data.verse}</b><br>${data.text}`;
    } catch (err) {
        verseResult.textContent = 'Kon vers niet ophalen. Controleer je invoer.';
    }
});

// Dagtekst ophalen
const daytextBtn = document.getElementById('getDaytext');
const daytextResult = document.getElementById('daytextResult');
daytextBtn?.addEventListener('click', async () => {
    daytextResult.textContent = 'Bezig met ophalen...';
    try {
        const res = await fetch('/api/daytext');
        if (!res.ok) throw new Error('Fout in API');
        const data = await res.json();
        daytextResult.innerHTML = `<b>${data.book} ${data.chapter}:${data.verse}</b><br>${data.text}`;
    } catch (err) {
        console.error('Kon dagtekst niet ophalen:', err);
        daytextResult.textContent = 'Kon dagtekst niet ophalen. ' + (err.message || err);
    }
});

// Laad boekenlijst in dropdown
async function loadBooksDropdown() {
    const select = document.getElementById('bookChapterSelect');
    if (!select) return;
    select.innerHTML = '<option value="">Laden...</option>';
    try {
        const res = await fetch('/api/books');
        const books = await res.json();
        select.innerHTML = books.map(book => `<option value="${book}">${book}</option>`).join('');
    } catch {
        select.innerHTML = '<option>Fout bij laden</option>';
    }
}
loadBooksDropdown();

// Hoofdstuk ophalen
const chapterForm = document.getElementById('chapterForm');
const chapterResult = document.getElementById('chapterResult');
chapterForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    chapterResult.textContent = 'Bezig met laden...';
    const book = document.getElementById('bookChapterSelect').value;
    const chapter = document.getElementById('chapterNum').value;
    try {
        const res = await fetch(`/api/chapter?book=${encodeURIComponent(book)}&chapter=${chapter}`);
        if (!res.ok) throw new Error('Niet gevonden of fout in API');
        const data = await res.json();
        let html = `<b>${data.book} ${data.chapter}</b><br><div class="card">`;
        for (const [vers, tekst] of Object.entries(data.verses)) {
            html += `<b>${vers}</b> ${tekst}<br>`;
        }
        html += '</div>';
        chapterResult.innerHTML = html;
    } catch (err) {
        chapterResult.textContent = 'Kon hoofdstuk niet ophalen. Controleer je invoer.';
    }
});

// Kopieerknoppen
function setupCopyButtons() {
    const btns = document.querySelectorAll('.copy-btn');
    btns.forEach(btn => {
        btn.addEventListener('click', () => {
            const url = btn.getAttribute('data-url');
            navigator.clipboard.writeText(url);
            btn.textContent = 'Gekopieerd!';
            btn.classList.add('copied');
            setTimeout(() => {
                btn.textContent = 'Kopieer';
                btn.classList.remove('copied');
            }, 1200);
        });
    });
}
setupCopyButtons();

// API test buttons
function setupApiTestButtons() {
    const btns = document.querySelectorAll('.api-test-btn');
    btns.forEach(btn => {
        btn.addEventListener('click', async () => {
            const url = btn.getAttribute('data-url');
            const resultDiv = btn.parentElement.querySelector('.api-test-result');
            resultDiv.textContent = 'Bezig...';
            try {
                const res = await fetch(url);
                const data = await res.json();
                resultDiv.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
            } catch (err) {
                resultDiv.textContent = 'Fout bij ophalen of geen geldige JSON.';
            }
        });
    });
}
setupApiTestButtons();
