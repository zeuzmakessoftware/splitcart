/* =========================================================
   SplitCart Web App — app.js
   Premium Curation UI with Backend Integration
   ========================================================= */

// ── Data Constants ──────────────────────────────────────────
const CATEGORIES = ['All', 'Produce', 'Protein', 'Pantry', 'Frozen', 'Snacks', 'Organic'];

const TAG_ICONS = {
  'Organic': '○', 'Sweet': '○', 'Vitamin C': '○', 'Grill Ready': '○',
  'High Protein': '○', 'Fresh Cut': '○', 'Shelf Stable': '○',
  'Dinner Base': '○', 'Clean Label': '○', 'Frozen': '○',
  'Smoothies': '○', 'No Sugar Added': '○', 'Crunchy': '○',
  'Party Snack': '○', 'Classic Salted': '○', 'Protein': '○',
  'Breakfast': '○', 'Family Pack': '○', 'Fresh': '○',
  'Salad Base': '○', 'Everyday Buy': '○',
};

// ── State ────────────────────────────────────────────────────
const state = {
  selectedCategory: 'All',
  userId: 'eva',         // Default user
  items: [],              // Now populated by API
  swipedIds: new Set(),
  likedIds: new Set(),
  lovedIds: new Set(),
  passedIds: new Set(),
  savedIds: new Set(),
  imageIndexes: {},       // id → currentImageIndex
  history: [],            // [{id, feedback}]
  currentItemId: null,
  isLoading: false,
};

// ── DOM refs ─────────────────────────────────────────────────
const $wrapper = document.getElementById('cardStackWrapper');
const $catScroll = document.getElementById('categoryScroll');
const $likedTop = document.getElementById('likedCountTop');
const $remainTop = document.getElementById('remainingCountTop');
const $badgeSwipe = document.getElementById('badge-swipe');
const $badgeLikes = document.getElementById('badge-likes');
const $badgeSaved = document.getElementById('badge-saved');
const $badgePass = document.getElementById('badge-pass');
const $uploadBtn = document.getElementById('uploadBtn');
const $receiptInput = document.getElementById('receiptInput');
const $userSelect = document.getElementById('userSelect');

// ── User Selection ───────────────────────────────────────────
$userSelect.addEventListener('change', (e) => {
  state.userId = e.target.value;
  // Reset session stats when switching users for training
  state.swipedIds.clear();
  state.likedIds.clear();
  state.lovedIds.clear();
  state.passedIds.clear();
  state.history = [];
  renderCard();
  updateStats();
});

// ── Feedback Logic (Synced to Backend) ───────────────────────
async function registerFeedback(feedback, item) {
  if (state.swipedIds.has(item.id)) return;
  state.swipedIds.add(item.id);
  state.history.push({ id: item.id, feedback });

  if (feedback === 'pass') state.passedIds.add(item.id);
  if (feedback === 'like') state.likedIds.add(item.id);
  if (feedback === 'love') state.lovedIds.add(item.id);

  // Sync to backend
  try {
    await fetch('http://localhost:5001/swipe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: state.userId,
        item: item,
        feedback: feedback
      })
    });
  } catch (err) {
    console.warn('Failed to sync swipe to backend:', err);
  }
}

// ── Helper Functions ────────────────────────────────────────
function availableItems() {
  return state.items.filter(item =>
    !state.swipedIds.has(item.id) &&
    (state.selectedCategory === 'All' || item.categories.includes(state.selectedCategory))
  );
}

function likedCount() {
  return state.likedIds.size + state.lovedIds.size;
}

function updateStats() {
  const avail = availableItems();
  const remaining = avail.length;
  const liked = likedCount();
  const saved = state.savedIds.size;
  const passed = state.passedIds.size;

  $likedTop.textContent = liked;
  $remainTop.textContent = remaining;

  $badgeSwipe.textContent = remaining;
  setBadge($badgeLikes, liked);
  setBadge($badgeSaved, saved);
  setBadge($badgePass, passed);
}

function setBadge(el, count) {
  el.textContent = count;
  if (count === 0) el.classList.add('hidden');
  else el.classList.remove('hidden');
}

// ── Category Tabs ───────────────────────────────────────────
function buildCategories() {
  $catScroll.innerHTML = '';
  CATEGORIES.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = 'cat-pill' + (cat === state.selectedCategory ? ' active' : '');
    btn.textContent = cat;
    btn.addEventListener('click', () => {
      state.selectedCategory = cat;
      buildCategories();
      renderCard();
      updateStats();
    });
    $catScroll.appendChild(btn);
  });
}

// ── API Integration ──────────────────────────────────────────
$uploadBtn.addEventListener('click', () => $receiptInput.click());

$receiptInput.addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const formData = new FormData();
  formData.append('receipt', file);

  state.isLoading = true;
  $wrapper.innerHTML = `
    <div class="empty-state">
      <div class="empty-state__icon">⏳</div>
      <div class="empty-state__title">Analyzing Receipt</div>
      <div class="empty-state__sub">Our AI concierge is itemizing and curating your grocery list...</div>
    </div>`;

  try {
    const response = await fetch('http://localhost:5001/upload', {
      method: 'POST',
      body: formData
    });
    const data = await response.json();

    if (data.error) throw new Error(data.error);

    // Reset state for new data
    state.items = data.items;
    state.swipedIds.clear();
    state.likedIds.clear();
    state.lovedIds.clear();
    state.passedIds.clear();
    state.savedIds.clear();
    state.history = [];
    state.imageIndexes = {};

    renderCard();
    updateStats();
    $navSplitBtn.style.display = 'flex'; // Show navigation entry
  } catch (err) {
    console.error(err);
    $wrapper.innerHTML = `
      <div class="empty-state">
        <div class="empty-state__icon">❌</div>
        <div class="empty-state__title">Upload Failed</div>
        <div class="empty-state__sub">${err.message}</div>
      </div>`;
  } finally {
    state.isLoading = false;
    $receiptInput.value = ''; // Reset input
  }
});

// ── Card Rendering ───────────────────────────────────────────
function renderCard() {
  $wrapper.innerHTML = '';
  const items = availableItems();

  if (items.length === 0) {
    const isStart = state.items.length === 0;
    $wrapper.innerHTML = `
      <div class="empty-state">
        <div class="empty-state__icon">${isStart ? '✦' : '✧'}</div>
        <div class="empty-state__title">${isStart ? 'Welcome to Splitcart' : 'Curation Complete'}</div>
        <div class="empty-state__sub">${isStart ? 'Upload a receipt to start your premium shopping experience.' : 'Your personal shopping model has been refined.'}</div>
      </div>`;
    state.currentItemId = null;
    return;
  }

  const item = items[0];
  state.currentItemId = item.id;
  if (state.imageIndexes[item.id] === undefined) state.imageIndexes[item.id] = 0;
  const imgIdx = state.imageIndexes[item.id];
  const isSaved = state.savedIds.has(item.id);

  const card = document.createElement('div');
  card.className = 'featured-card card-enter';
  card.id = 'currentCard';

  const imgHtml = item.images.map((url, i) =>
    `<img src="${url}" alt="${item.name}" class="${i === imgIdx ? '' : 'hidden'}" draggable="false" />`
  ).join('');

  const dotsHtml = item.images.length > 1
    ? `<div class="page-dots">${item.images.map((_, i) =>
      `<div class="page-dot ${i === imgIdx ? 'active' : ''}"></div>`
    ).join('')}</div>`
    : '<div class="page-dots"></div>';

  const tagsHtml = item.tags.map(tag =>
    `<span class="tag-chip"><span class="tag-icon">${TAG_ICONS[tag] || '○'}</span>${tag}</span>`
  ).join('');

  card.innerHTML = `
    <div class="card-image">${imgHtml}</div>
    <div class="card-gradient"></div>
    <div class="swipe-badge swipe-badge--pass" id="badge-pass-overlay">NO</div>
    <div class="swipe-badge swipe-badge--like" id="badge-like-overlay">YES</div>
    <div class="card-content">
      ${dotsHtml}
      <div class="card-spacer"></div>
      <div class="card-text">
        <div class="card-brand">${item.brand.toUpperCase()}</div>
        <div class="card-name">${item.name}</div>
        <div class="card-detail">${item.detail}</div>
      </div>
      <div class="card-tags">${tagsHtml}</div>
      <div class="card-note">${item.note}</div>
      <div class="action-row">
        <button class="action-btn action-btn--undo" id="btn-undo"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-3.5"/></svg></button>
        <button class="action-btn action-btn--pass" id="btn-pass"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
        <button class="action-btn action-btn--love" id="btn-love"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg></button>
        <button class="action-btn action-btn--like" id="btn-like"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5A5.5 5.5 0 0 1 7.5 3c1.74 0 3.41.81 4.5 2.09A5.99 5.99 0 0 1 16.5 3 5.5 5.5 0 0 1 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg></button>
        <button class="action-btn action-btn--save ${isSaved ? 'saved' : ''}" id="btn-save"><svg width="16" height="16" viewBox="0 0 24 24" fill="${isSaved ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg></button>
      </div>
    </div>
    <div class="img-tap-zones" id="imgTapZones">
      <div class="img-tap-left" id="tapLeft"></div>
      <div class="img-tap-right" id="tapRight"></div>
    </div>
  `;

  $wrapper.appendChild(card);

  document.getElementById('btn-undo').addEventListener('click', e => { e.stopPropagation(); undoLastSwipe(); });
  document.getElementById('btn-pass').addEventListener('click', e => { e.stopPropagation(); animateAndSwipe('pass', item); });
  document.getElementById('btn-love').addEventListener('click', e => { e.stopPropagation(); animateAndSwipe('love', item); });
  document.getElementById('btn-like').addEventListener('click', e => { e.stopPropagation(); animateAndSwipe('like', item); });
  document.getElementById('btn-save').addEventListener('click', e => { e.stopPropagation(); toggleSave(item); });

  document.getElementById('tapLeft').addEventListener('click', () => advanceImage(item, false));
  document.getElementById('tapRight').addEventListener('click', () => advanceImage(item, true));

  initSwipeGesture(card, item);
}

// ── Image Navigation ─────────────────────────────────────────
function advanceImage(item, forward) {
  if (item.images.length <= 1) return;
  const cur = state.imageIndexes[item.id] ?? 0;
  const next = forward ? Math.min(cur + 1, item.images.length - 1) : Math.max(cur - 1, 0);
  state.imageIndexes[item.id] = next;
  const card = document.getElementById('currentCard');
  if (!card) return;
  const imgs = card.querySelectorAll('.card-image img');
  imgs.forEach((img, i) => { img.classList.toggle('hidden', i !== next); });
  const dots = card.querySelectorAll('.page-dot');
  dots.forEach((dot, i) => { dot.classList.toggle('active', i === next); });
}

// ── Save Toggle ──────────────────────────────────────────────
function toggleSave(item) {
  if (state.savedIds.has(item.id)) state.savedIds.delete(item.id);
  else state.savedIds.add(item.id);
  const btn = document.getElementById('btn-save');
  if (btn) {
    const isSaved = state.savedIds.has(item.id);
    btn.classList.toggle('saved', isSaved);
    btn.querySelector('svg').setAttribute('fill', isSaved ? 'currentColor' : 'none');
  }
  updateStats();
}

// ── Swipe Gesture ────────────────────────────────────────────
function initSwipeGesture(card, item) {
  let startX = 0, currentX = 0, isDragging = false;
  const THRESHOLD = card.offsetWidth * 0.24;
  const badgePass = document.getElementById('badge-pass-overlay');
  const badgeLike = document.getElementById('badge-like-overlay');

  function onPointerDown(e) {
    if (e.target.closest('.action-btn') || e.target.closest('.img-tap-zones')) return;
    isDragging = true;
    startX = e.clientX ?? e.touches?.[0]?.clientX ?? 0;
    currentX = 0;
    card.style.transition = 'none';
    document.getElementById('imgTapZones').classList.remove('active');
  }

  function onPointerMove(e) {
    if (!isDragging) return;
    const x = (e.clientX ?? e.touches?.[0]?.clientX ?? startX) - startX;
    currentX = x;
    const rot = x / 22;
    card.style.transform = `translateX(${x}px) rotate(${rot}deg)`;
    const progress = Math.min(Math.abs(x) / 110, 1);
    if (x < 0) { badgePass.style.opacity = progress; badgeLike.style.opacity = 0; }
    else if (x > 0) { badgeLike.style.opacity = progress; badgePass.style.opacity = 0; }
  }

  function onPointerUp() {
    if (!isDragging) return;
    isDragging = false;
    document.getElementById('imgTapZones')?.classList.add('active');
    if (currentX > THRESHOLD) animateAndSwipe('like', item, currentX);
    else if (currentX < -THRESHOLD) animateAndSwipe('pass', item, currentX);
    else {
      card.style.transition = 'transform 0.32s cubic-bezier(0.34,1.56,0.64,1)';
      card.style.transform = '';
      badgePass.style.opacity = 0; badgeLike.style.opacity = 0;
    }
  }

  card.addEventListener('mousedown', onPointerDown);
  card.addEventListener('touchstart', onPointerDown, { passive: true });
  window.addEventListener('mousemove', onPointerMove);
  window.addEventListener('touchmove', onPointerMove, { passive: true });
  window.addEventListener('mouseup', onPointerUp);
  window.addEventListener('touchend', onPointerUp);
}

// ── Feedback & Swipe Animation ───────────────────────────────
function animateAndSwipe(feedback, item) {
  const card = document.getElementById('currentCard');
  if (!card) return;
  const dir = (feedback === 'pass') ? -1 : 1;
  const exitX = dir * (card.offsetWidth * 1.3);
  card.style.transition = 'transform 0.22s ease-in, opacity 0.22s ease-in';
  card.style.transform = `translateX(${exitX}px) rotate(${dir * 14}deg)`;
  card.style.opacity = '0';
  setTimeout(() => {
    registerFeedback(feedback, item);
    renderCard();
    updateStats();
  }, 200);
}

function registerFeedback(feedback, item) {
  if (state.swipedIds.has(item.id)) return;
  state.swipedIds.add(item.id);
  state.history.push({ id: item.id, feedback });
  if (feedback === 'pass') state.passedIds.add(item.id);
  if (feedback === 'like') state.likedIds.add(item.id);
  if (feedback === 'love') state.lovedIds.add(item.id);
}

function undoLastSwipe() {
  const last = state.history.pop();
  if (!last) return;
  state.swipedIds.delete(last.id);
  state.passedIds.delete(last.id);
  state.likedIds.delete(last.id);
  state.lovedIds.delete(last.id);
  renderCard();
  updateStats();
}

const $navSplitBtn = document.getElementById('navSplitBtn');
const $curationView = document.getElementById('curationView');
const $splitView = document.getElementById('splitView');
const $splitContainer = document.getElementById('splitResultsContainer');
const $appTitle = document.getElementById('appTitle');

// ── Navigation ──────────────────────────────────────────────
$navSplitBtn.addEventListener('click', () => {
  showSplitView();
});

$appTitle.addEventListener('click', () => {
  showCurationView();
});

function showCurationView() {
  $curationView.style.display = 'block';
  $splitView.style.display = 'none';
  $appTitle.style.cursor = 'default';
}

async function showSplitView() {
  $curationView.style.display = 'none';
  $splitView.style.display = 'block';
  $appTitle.style.cursor = 'pointer';

  if (state.items.length === 0) return;

  $splitContainer.innerHTML = '<div class="loading-results">✦ Analyzing individual profiles...</div>';

  try {
    const response = await fetch('http://localhost:5001/split', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: state.items })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);

    renderPremiumSplitReport(data);
  } catch (err) {
    $splitContainer.innerHTML = `<div class="error-results">Failed to split: ${err.message}</div>`;
  }
}

function renderPremiumSplitReport(data) {
  const { assignment, summary } = data;
  let html = '';

  // Group by assigned_to
  const groups = {};
  assignment.forEach(a => {
    if (!groups[a.assigned_to]) groups[a.assigned_to] = [];
    groups[a.assigned_to].push(a);
  });

  for (const [user, items] of Object.entries(groups)) {
    const total = summary[user].toFixed(2);
    html += `
      <div class="result-group-card">
        <div class="group-header">
          <span class="group-user">${user === 'eva' ? 'Eva' : user === 'john' ? 'John' : 'Shared'}</span>
          <span class="group-total">$${total}</span>
        </div>
        <div class="group-items">
          ${items.map(item => `
            <div class="item-row">
              <div class="item-info">
                <span class="item-label">${item.item_name}</span>
                <span class="item-sub">Based on your training profile</span>
              </div>
              <span class="item-cost">${item.price}</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }

  $splitContainer.innerHTML = html;
}

// Update the upload success to show nav icon
// (Inside handleReceipt will be updated in next step or combined)

init();
