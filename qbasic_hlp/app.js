/**
 * QBasic Help Portal - Interactive Single Page Application Engine
 * Reads offline data from QBASIC_HELP_TOPICS, QBASIC_HELP_CONTEXTS, and QBASIC_HELP_NAV
 */

(function () {
  'use strict';

  // State
  let currentTopicId = 'T0000';
  let currentTheme = localStorage.getItem('qb_help_theme') || 'retro';
  let currentFontSize = parseInt(localStorage.getItem('qb_help_fontsize') || '13', 10);
  let activeTab = 'toc';
  let activeLetter = 'ALL';
  let searchDebounceTimer = null;

  // Fast Lookup Map: ID -> Topic
  const topicMap = new Map();
  if (typeof QBASIC_HELP_TOPICS !== 'undefined') {
    for (const t of QBASIC_HELP_TOPICS) {
      topicMap.set(t.id, t);
    }
  }

  // DOM Elements
  const elements = {
    app: document.getElementById('app'),
    topicContent: document.getElementById('topic-content'),
    topicScrollArea: document.getElementById('topic-scroll-area'),
    breadcrumbText: document.getElementById('breadcrumb-topic'),
    sidebar: document.getElementById('sidebar'),
    searchInput: document.getElementById('global-search'),
    searchTabBtn: document.getElementById('tab-search-btn'),
    themeBtn: document.getElementById('btn-theme'),
    fontIncBtn: document.getElementById('btn-font-inc'),
    fontDecBtn: document.getElementById('btn-font-dec'),
    copyBtn: document.getElementById('btn-copy-example'),
    toggleSidebarBtn: document.getElementById('btn-toggle-sidebar'),
    toast: document.getElementById('toast'),
    // Tab containers
    tabToc: document.getElementById('tab-toc'),
    tabIndex: document.getElementById('tab-index'),
    tabCategories: document.getElementById('tab-categories'),
    tabSearch: document.getElementById('tab-search'),
    searchResults: document.getElementById('search-results'),
    indexItemsList: document.getElementById('index-items-list'),
    alphaBar: document.getElementById('alpha-bar')
  };

  // Initialize Application
  function init() {
    applyTheme(currentTheme);
    applyFontSize(currentFontSize);
    renderTOC();
    renderAlphabetBar();
    renderIndexList('ALL');
    renderCategories();
    setupEventListeners();

    // Handle URL hash on boot
    handleRoute();
    window.addEventListener('hashchange', handleRoute);
  }

  // Route Handling
  function handleRoute() {
    let hash = window.location.hash.replace(/^#/, '').trim();
    if (!hash) {
      hash = 'T0000';
    }

    // Check if hash is a command or context keyword
    if (hash.startsWith('search=')) {
      const query = decodeURIComponent(hash.substring(7));
      elements.searchInput.value = query;
      switchTab('search');
      performSearch(query);
      return;
    }

    // Direct Topic ID match
    let targetId = null;
    if (/^T[0-9A-Fa-f]{4}$/.test(hash)) {
      targetId = hash.toUpperCase();
    } else if (typeof QBASIC_HELP_CONTEXTS !== 'undefined') {
      // Check context lookup
      targetId = QBASIC_HELP_CONTEXTS[hash.toUpperCase()] ||
        QBASIC_HELP_CONTEXTS[hash] ||
        QBASIC_HELP_CONTEXTS[hash.toLowerCase()];
    }

    // If not found in contexts, search topic title match
    if (!targetId) {
      const found = QBASIC_HELP_TOPICS.find(t =>
        t.title && t.title.toLowerCase().startsWith(hash.toLowerCase())
      );
      if (found) targetId = found.id;
    }

    if (targetId && topicMap.has(targetId)) {
      loadTopic(targetId);
    } else {
      loadTopic('T0000');
    }
  }

  function navigateTo(target) {
    if (!target) return;
    if (target.startsWith('T') && target.length === 5) {
      window.location.hash = target;
    } else {
      window.location.hash = encodeURIComponent(target);
    }
  }

  // Load and Render Topic
  function loadTopic(topicId) {
    const topic = topicMap.get(topicId);
    if (!topic) return;

    currentTopicId = topicId;
    document.title = `${topic.title || topicId} - QBasic Help System`;

    // Update Breadcrumb
    elements.breadcrumbText.textContent = topic.title || topicId;

    // Render HTML content
    let html = topic.html || '';

    // Extract Example if present to offer copy action
    const exampleText = extractExampleCode(topic.text);
    if (exampleText && elements.copyBtn) {
      elements.copyBtn.style.display = 'inline-flex';
      elements.copyBtn.onclick = () => copyToClipboard(exampleText, 'Exemple copié dans le presse-papier !');
    } else if (elements.copyBtn) {
      elements.copyBtn.style.display = 'none';
    }

    elements.topicContent.innerHTML = html;
    elements.topicScrollArea.scrollTop = 0;

    // Attach click interceptors to links inside the content
    const links = elements.topicContent.querySelectorAll('a');
    links.forEach(a => {
      const href = a.getAttribute('href');
      if (!href) return;

      if (href.startsWith('T') && href.endsWith('.html')) {
        const id = href.replace('.html', '');
        a.onclick = (e) => {
          e.preventDefault();
          navigateTo(id);
        };
      } else if (href === 'javascript:history.back()' || href === '#!B') {
        a.onclick = (e) => {
          e.preventDefault();
          window.history.back();
        };
      } else if (href.startsWith('#')) {
        const ctx = href.substring(1);
        a.onclick = (e) => {
          e.preventDefault();
          navigateTo(ctx);
        };
      }
    });

    // Highlight active item in sidebars
    updateSidebarActive(topicId);
  }

  // Helper: Extract code example from plain text
  function extractExampleCode(text) {
    if (!text) return null;
    const exIndex = text.indexOf('Example:');
    if (exIndex === -1) return null;

    let codePart = text.substring(exIndex + 8);
    const seeAlsoIndex = codePart.indexOf('See Also');
    if (seeAlsoIndex !== -1) {
      codePart = codePart.substring(0, seeAlsoIndex);
    }
    return codePart.trim();
  }

  // Copy to Clipboard with Toast Notification
  function copyToClipboard(text, message) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(() => {
      showToast(message || 'Copié !');
    }).catch(() => {
      // Fallback for older browsers
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      showToast(message || 'Copié !');
    });
  }

  function showToast(msg) {
    if (!elements.toast) return;
    elements.toast.textContent = msg;
    elements.toast.classList.add('show');
    setTimeout(() => {
      elements.toast.classList.remove('show');
    }, 2200);
  }

  // Render Table of Contents
  function renderTOC() {
    if (!QBASIC_HELP_NAV || !QBASIC_HELP_NAV.toc) return;
    let html = '';
    for (const section of QBASIC_HELP_NAV.toc) {
      html += `<div class="nav-group">`;
      html += `<div class="nav-group-title"><span>${section.icon || '📁'}</span> ${section.title}</div>`;
      for (const item of section.items) {
        html += `<div class="nav-item" data-id="${item.id}" onclick="QBasicPortal.navigateTo('${item.id}')">`;
        html += `  <span>${item.title}</span>`;
        html += `  <span class="badge" style="opacity:0.6">${item.id}</span>`;
        html += `</div>`;
      }
      html += `</div>`;
    }
    elements.tabToc.innerHTML = html;
  }

  // Render Alphabet Bar for Index
  function renderAlphabetBar() {
    if (!QBASIC_HELP_NAV || !QBASIC_HELP_NAV.indexLetters) return;
    let html = `<span class="alpha-chip active" data-letter="ALL" onclick="QBasicPortal.filterIndex('ALL')">TOUS</span>`;
    for (const l of QBASIC_HELP_NAV.indexLetters) {
      html += `<span class="alpha-chip" data-letter="${l}" onclick="QBasicPortal.filterIndex('${l}')">${l}</span>`;
    }
    elements.alphaBar.innerHTML = html;
  }

  // Render Index List
  function renderIndexList(letter) {
    activeLetter = letter;
    if (!QBASIC_HELP_NAV) return;

    // Update active chip
    const chips = elements.alphaBar.querySelectorAll('.alpha-chip');
    chips.forEach(c => {
      if (c.getAttribute('data-letter') === letter) c.classList.add('active');
      else c.classList.remove('active');
    });

    let entries = [];
    if (letter === 'ALL') {
      entries = QBASIC_HELP_NAV.indexFlat || [];
    } else {
      entries = (QBASIC_HELP_NAV.indexByLetter && QBASIC_HELP_NAV.indexByLetter[letter]) || [];
    }

    let html = '';
    for (const item of entries) {
      let badgeClass = 'badge-keyword';
      if (item.kind === 'Statement') badgeClass = 'badge-statement';
      else if (item.kind === 'Function') badgeClass = 'badge-function';
      else if (item.kind === 'Operator') badgeClass = 'badge-operator';
      else if (item.kind === 'Metacommand') badgeClass = 'badge-metacommand';

      html += `<div class="nav-item" data-id="${item.id}" onclick="QBasicPortal.navigateTo('${item.id}')">`;
      html += `  <span><b>${item.name}</b></span>`;
      html += `  <span class="badge ${badgeClass}">${item.kind}</span>`;
      html += `</div>`;
    }

    if (entries.length === 0) {
      html = `<div style="padding:16px;color:var(--qb-text-dim);text-align:center;">Aucune entrée pour la lettre "${letter}"</div>`;
    }

    elements.indexItemsList.innerHTML = html;
    updateSidebarActive(currentTopicId);
  }

  // Render Categories
  function renderCategories() {
    if (!QBASIC_HELP_NAV || !QBASIC_HELP_NAV.categories) return;
    let html = '';
    for (const cat of QBASIC_HELP_NAV.categories) {
      html += `<div class="nav-group">`;
      html += `<div class="nav-group-title"><span>${cat.icon}</span> ${cat.name} (${cat.items.length})</div>`;
      for (const item of cat.items) {
        html += `<div class="nav-item" data-id="${item.id}" onclick="QBasicPortal.navigateTo('${item.id}')">`;
        html += `  <span>${item.keyword}</span>`;
        html += `  <span class="badge" style="opacity:0.6">${item.id}</span>`;
        html += `</div>`;
      }
      html += `</div>`;
    }
    elements.tabCategories.innerHTML = html;
  }

  // Highlight Active Item in Sidebar
  function updateSidebarActive(topicId) {
    document.querySelectorAll('.nav-item').forEach(el => {
      if (el.getAttribute('data-id') === topicId) {
        el.classList.add('active');
      } else {
        el.classList.remove('active');
      }
    });
  }

  // Tab Switching
  function switchTab(tabName) {
    activeTab = tabName;
    document.querySelectorAll('.tab-btn').forEach(b => {
      if (b.getAttribute('data-tab') === tabName) b.classList.add('active');
      else b.classList.remove('active');
    });

    elements.tabToc.style.display = tabName === 'toc' ? 'block' : 'none';
    elements.tabIndex.style.display = tabName === 'index' ? 'block' : 'none';
    elements.tabCategories.style.display = tabName === 'categories' ? 'block' : 'none';
    elements.tabSearch.style.display = tabName === 'search' ? 'block' : 'none';
  }

  // Full-Text Search Engine
  function performSearch(query) {
    query = (query || '').trim().toLowerCase();
    if (!query) {
      elements.searchResults.innerHTML = '<div style="padding:16px;color:var(--qb-text-dim);text-align:center;">Tapez un mot-clé pour lancer la recherche...</div>';
      return;
    }

    const results = [];
    for (const topic of QBASIC_HELP_TOPICS) {
      let score = 0;
      const titleLower = (topic.title || '').toLowerCase();
      const textLower = (topic.text || '').toLowerCase();

      // Check contexts
      if (topic.contexts) {
        for (const c of topic.contexts) {
          const cl = c.toLowerCase();
          if (cl === query) score += 120;
          else if (cl.startsWith(query)) score += 60;
          else if (cl.includes(query)) score += 30;
        }
      }

      // Check title
      if (titleLower === query) score += 100;
      else if (titleLower.startsWith(query)) score += 70;
      else if (titleLower.includes(query)) score += 40;

      // Check text occurrences
      const idx = textLower.indexOf(query);
      if (idx !== -1) {
        score += 15;
        // Count additional matches
        let count = 0;
        let pos = idx;
        while ((pos = textLower.indexOf(query, pos + query.length)) !== -1 && count < 10) {
          count++;
          score += 2;
        }
      }

      if (score > 0) {
        // Generate snippet
        let snippet = '';
        if (idx !== -1) {
          const start = Math.max(0, idx - 45);
          const end = Math.min(topic.text.length, idx + query.length + 65);
          let snippetRaw = topic.text.substring(start, end).replace(/[\r\n]+/g, ' ');
          // Highlight match in snippet
          const reg = new RegExp(`(${escapeRegExp(query)})`, 'gi');
          snippet = (start > 0 ? '...' : '') + snippetRaw.replace(reg, '<mark>$1</mark>') + (end < topic.text.length ? '...' : '');
        } else {
          snippet = (topic.text || '').substring(0, 100).replace(/[\r\n]+/g, ' ') + '...';
        }

        results.push({
          id: topic.id,
          title: topic.title,
          score: score,
          snippet: snippet
        });
      }
    }

    results.sort((a, b) => b.score - a.score);

    if (results.length === 0) {
      elements.searchResults.innerHTML = `<div style="padding:16px;color:var(--qb-text-dim);text-align:center;">Aucun résultat pour "<b>${escapeHtml(query)}</b>".</div>`;
      return;
    }

    let html = `<div style="padding:8px 12px;font-size:11px;color:var(--qb-highlight);border-bottom:1px solid var(--qb-border);"><b>${results.length}</b> résultats trouvés</div>`;
    for (const res of results.slice(0, 50)) {
      html += `<div class="search-result-item" onclick="QBasicPortal.navigateTo('${res.id}')">`;
      html += `  <div class="search-result-title"><span>${escapeHtml(res.title)}</span> <span class="badge">${res.id}</span></div>`;
      html += `  <div class="search-result-snippet">${res.snippet}</div>`;
      html += `</div>`;
    }

    elements.searchResults.innerHTML = html;
  }

  function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function escapeHtml(string) {
    if (!string) return '';
    return string.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // Theme Management
  function toggleTheme() {
    if (currentTheme === 'retro') applyTheme('dark');
    else if (currentTheme === 'dark') applyTheme('light');
    else applyTheme('retro');
  }

  function applyTheme(theme) {
    currentTheme = theme;
    localStorage.setItem('qb_help_theme', theme);
    document.body.className = '';
    if (theme === 'dark') document.body.classList.add('theme-dark');
    else if (theme === 'light') document.body.classList.add('theme-light');

    if (elements.themeBtn) {
      let label = '🎮 DOS Rétro';
      if (theme === 'dark') label = '🌙 Sombre';
      else if (theme === 'light') label = '☀️ Clair';
      elements.themeBtn.innerHTML = `<span>🎨</span> ${label}`;
    }
  }

  // Font Size Management
  function applyFontSize(size) {
    currentFontSize = Math.max(11, Math.min(22, size));
    localStorage.setItem('qb_help_fontsize', currentFontSize);
    elements.topicContent.style.fontSize = `${currentFontSize}px`;
  }

  // Event Listeners
  function setupEventListeners() {
    // Tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        switchTab(btn.getAttribute('data-tab'));
      });
    });

    // Search Input
    elements.searchInput.addEventListener('input', (e) => {
      clearTimeout(searchDebounceTimer);
      const val = e.target.value;
      searchDebounceTimer = setTimeout(() => {
        if (val.trim()) {
          switchTab('search');
          performSearch(val);
        }
      }, 180);
    });

    // Keyboard Shortcut: Ctrl+K or / to search, Esc to clear
    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey && e.key === 'k') || (e.key === '/' && document.activeElement !== elements.searchInput)) {
        e.preventDefault();
        elements.searchInput.focus();
        elements.searchInput.select();
      } else if (e.key === 'Escape' && document.activeElement === elements.searchInput) {
        elements.searchInput.blur();
      }
    });

    // Theme Toggle
    elements.themeBtn.addEventListener('click', toggleTheme);

    // Font Adjusters
    elements.fontIncBtn.addEventListener('click', () => applyFontSize(currentFontSize + 1));
    elements.fontDecBtn.addEventListener('click', () => applyFontSize(currentFontSize - 1));

    // Toggle Sidebar
    elements.toggleSidebarBtn.addEventListener('click', () => {
      elements.sidebar.classList.toggle('collapsed');
    });
  }

  // Expose Global API
  window.QBasicPortal = {
    navigateTo: navigateTo,
    filterIndex: renderIndexList,
    switchTab: switchTab,
    toggleTheme: toggleTheme,
    copyToClipboard: copyToClipboard
  };

  // Auto-run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

