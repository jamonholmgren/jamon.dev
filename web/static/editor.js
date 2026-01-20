// Inline Content Editor for jamon.dev (dev mode only)
(function() {
  'use strict';

  // Only run in dev mode
  if (!window.JAMON_DEV_MODE) return;

  // Editor state
  const state = {
    isDirty: false,
    filePath: window.JAMON_FILE_PATH || '',
    pageTitle: window.JAMON_PAGE_TITLE || '',
    isBlog: false,
    originalContent: {},
    currentArticleId: null,
    editMode: true
  };

  // Determine if we're on a blog page
  state.isBlog = location.pathname.startsWith('/blog');

  // Initialize editor when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  function init() {
    if (state.isBlog) {
      initBlogEditor();
    } else {
      initPageEditor();
    }
    createToolbar();
    createSelectionToolbar();
    setupKeyboardShortcuts();
    setupBeforeUnload();
  }

  // Initialize editor for regular pages
  function initPageEditor() {
    const main = document.querySelector('main');
    if (!main) return;

    // Store original content
    state.originalContent.main = main.innerHTML;

    // Create title input
    const titleContainer = document.createElement('div');
    titleContainer.className = 'editor-title-container';
    titleContainer.innerHTML = `
      <label for="editor-title">Page Title:</label>
      <input type="text" id="editor-title" value="${escapeHtml(state.pageTitle)}" />
    `;
    main.insertBefore(titleContainer, main.firstChild);

    // Track title changes
    const titleInput = document.getElementById('editor-title');
    titleInput.addEventListener('input', () => {
      markDirty();
    });

    // Make main content editable (excluding the title input)
    const editableContent = document.createElement('div');
    editableContent.className = 'editor-content';
    editableContent.contentEditable = 'true';

    // Move all content after title container into editable div
    while (titleContainer.nextSibling) {
      editableContent.appendChild(titleContainer.nextSibling);
    }
    main.appendChild(editableContent);

    // Store reference
    state.editableElement = editableContent;

    // Track content changes
    editableContent.addEventListener('input', () => {
      markDirty();
    });

    // Handle paste - clean up HTML
    editableContent.addEventListener('paste', handlePaste);
  }

  // Initialize editor for blog pages
  function initBlogEditor() {
    const articles = document.querySelectorAll('article[id]');

    articles.forEach(article => {
      const articleId = article.id;

      // Store original content
      state.originalContent[articleId] = article.innerHTML;

      // Make editable
      article.contentEditable = 'true';
      article.dataset.editable = 'true';

      // Track changes
      article.addEventListener('input', () => {
        state.currentArticleId = articleId;
        markDirty();
      });

      // Handle paste
      article.addEventListener('paste', handlePaste);

      // Track focus
      article.addEventListener('focus', () => {
        state.currentArticleId = articleId;
      });
    });
  }

  // Create main toolbar
  function createToolbar() {
    const toolbar = document.createElement('div');
    toolbar.className = 'editor-toolbar';
    toolbar.innerHTML = `
      <div class="editor-toolbar-status">
        <span class="editor-status-indicator"></span>
        <span class="editor-status-text">Ready</span>
      </div>
      <div class="editor-toolbar-actions">
        <label class="editor-toggle">
          <input type="checkbox" checked>
          <span class="editor-toggle-slider"></span>
          <span class="editor-toggle-label">Edit</span>
        </label>
        <button class="editor-btn editor-btn-discard" disabled>Discard</button>
        <button class="editor-btn editor-btn-save" disabled>Save</button>
      </div>
    `;
    document.body.appendChild(toolbar);

    // Edit mode toggle
    toolbar.querySelector('.editor-toggle input').addEventListener('change', (e) => {
      toggleEditMode(e.target.checked);
    });

    // Save button
    toolbar.querySelector('.editor-btn-save').addEventListener('click', saveContent);

    // Discard button
    toolbar.querySelector('.editor-btn-discard').addEventListener('click', discardChanges);

    state.toolbar = toolbar;
  }

  // Toggle edit mode on/off
  function toggleEditMode(enabled) {
    state.editMode = enabled;

    if (state.isBlog) {
      // Toggle all articles
      const articles = document.querySelectorAll('article[data-editable]');
      articles.forEach(article => {
        article.contentEditable = enabled ? 'true' : 'false';
      });
    } else {
      // Toggle page content
      if (state.editableElement) {
        state.editableElement.contentEditable = enabled ? 'true' : 'false';
      }
      // Toggle title input
      const titleInput = document.getElementById('editor-title');
      if (titleInput) {
        titleInput.disabled = !enabled;
      }
    }

    // Update toolbar state
    const statusText = state.toolbar.querySelector('.editor-status-text');
    if (enabled) {
      statusText.textContent = state.isDirty ? 'Unsaved changes' : 'Ready';
      document.body.classList.remove('editor-view-mode');
    } else {
      statusText.textContent = 'View mode';
      document.body.classList.add('editor-view-mode');
      hideSelectionToolbar();
    }
  }

  // Create selection toolbar for formatting
  function createSelectionToolbar() {
    const selToolbar = document.createElement('div');
    selToolbar.className = 'editor-selection-toolbar';
    selToolbar.innerHTML = `
      <button data-cmd="bold" title="Bold (Cmd+B)"><strong>B</strong></button>
      <button data-cmd="italic" title="Italic (Cmd+I)"><em>I</em></button>
      <button data-cmd="createLink" title="Link (Cmd+K)">Link</button>
      <span class="editor-sel-divider"></span>
      <button data-cmd="formatBlock" data-value="h2" title="Heading 2">H2</button>
      <button data-cmd="formatBlock" data-value="h3" title="Heading 3">H3</button>
      <button data-cmd="formatBlock" data-value="p" title="Paragraph">P</button>
    `;
    document.body.appendChild(selToolbar);

    // Handle formatting commands
    selToolbar.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('mousedown', (e) => {
        e.preventDefault(); // Prevent losing selection
      });
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const cmd = btn.dataset.cmd;
        const value = btn.dataset.value || null;

        if (cmd === 'createLink') {
          const url = prompt('Enter URL:');
          if (url) {
            document.execCommand(cmd, false, url);
            markDirty();
          }
        } else if (cmd === 'formatBlock') {
          document.execCommand(cmd, false, '<' + value + '>');
          markDirty();
        } else {
          document.execCommand(cmd, false, value);
          markDirty();
        }

        hideSelectionToolbar();
      });
    });

    state.selectionToolbar = selToolbar;

    // Show/hide selection toolbar based on selection
    document.addEventListener('selectionchange', () => {
      const selection = window.getSelection();
      if (selection.isCollapsed || selection.toString().trim() === '') {
        hideSelectionToolbar();
        return;
      }

      // Check if selection is within editable area
      const anchorNode = selection.anchorNode;
      if (!anchorNode) return;

      const editableParent = anchorNode.parentElement?.closest('[contenteditable="true"]');
      if (!editableParent) {
        hideSelectionToolbar();
        return;
      }

      showSelectionToolbar(selection);
    });
  }

  function showSelectionToolbar(selection) {
    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();

    state.selectionToolbar.style.display = 'flex';
    state.selectionToolbar.style.top = (rect.top - 45 + window.scrollY) + 'px';
    state.selectionToolbar.style.left = (rect.left + rect.width / 2 - state.selectionToolbar.offsetWidth / 2) + 'px';
  }

  function hideSelectionToolbar() {
    if (state.selectionToolbar) {
      state.selectionToolbar.style.display = 'none';
    }
  }

  // Handle paste - strip formatting
  function handlePaste(e) {
    e.preventDefault();
    const text = e.clipboardData.getData('text/plain');
    document.execCommand('insertText', false, text);
  }

  // Mark content as dirty (modified)
  function markDirty() {
    if (!state.isDirty) {
      state.isDirty = true;
      updateToolbarState();
    }
  }

  // Update toolbar state
  function updateToolbarState() {
    const saveBtn = state.toolbar.querySelector('.editor-btn-save');
    const discardBtn = state.toolbar.querySelector('.editor-btn-discard');
    const statusIndicator = state.toolbar.querySelector('.editor-status-indicator');
    const statusText = state.toolbar.querySelector('.editor-status-text');

    if (state.isDirty) {
      saveBtn.disabled = false;
      discardBtn.disabled = false;
      statusIndicator.className = 'editor-status-indicator dirty';
      statusText.textContent = 'Unsaved changes';
    } else {
      saveBtn.disabled = true;
      discardBtn.disabled = true;
      statusIndicator.className = 'editor-status-indicator';
      statusText.textContent = 'Ready';
    }
  }

  // Save content
  async function saveContent() {
    if (!state.isDirty) return;

    const statusText = state.toolbar.querySelector('.editor-status-text');
    statusText.textContent = 'Saving...';

    try {
      if (state.isBlog) {
        await saveBlogArticle();
      } else {
        await savePage();
      }

      state.isDirty = false;
      updateToolbarState();
      showToast('Saved successfully!', 'success');

      // Update original content
      if (state.isBlog && state.currentArticleId) {
        const article = document.getElementById(state.currentArticleId);
        if (article) {
          state.originalContent[state.currentArticleId] = article.innerHTML;
        }
      } else if (state.editableElement) {
        state.originalContent.main = state.editableElement.innerHTML;
      }
    } catch (err) {
      console.error('Save error:', err);
      showToast('Save failed: ' + err.message, 'error');
      statusText.textContent = 'Save failed';
    }
  }

  // Save a regular page
  async function savePage() {
    const titleInput = document.getElementById('editor-title');
    const title = titleInput.value.trim();
    const content = state.editableElement.innerHTML.trim();

    // Clean path - remove leading slash if present
    let path = state.filePath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    const formData = new URLSearchParams();
    formData.append('path', path);
    formData.append('title', title);
    formData.append('content', content);

    const response = await fetch('/api/save-page', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData.toString()
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.error || 'Save failed');
    }
  }

  // Save a blog article
  async function saveBlogArticle() {
    if (!state.currentArticleId) {
      throw new Error('No article selected');
    }

    const article = document.getElementById(state.currentArticleId);
    if (!article) {
      throw new Error('Article not found');
    }

    // Get the year from the article's data attribute or from the URL
    const year = article.dataset.year || location.pathname.split('/').pop();

    // Build the full article HTML including the opening tag with attributes
    const articleHtml = `<article id="${state.currentArticleId}" data-year="${year}">
${article.innerHTML.trim()}
</article>`;

    const formData = new URLSearchParams();
    formData.append('articleId', state.currentArticleId);
    formData.append('year', year);
    formData.append('content', articleHtml);

    const response = await fetch('/api/save-article', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData.toString()
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.error || 'Save failed');
    }
  }

  // Discard changes
  function discardChanges() {
    if (!state.isDirty) return;

    if (!confirm('Discard all changes?')) return;

    if (state.isBlog) {
      // Restore all articles
      Object.keys(state.originalContent).forEach(articleId => {
        const article = document.getElementById(articleId);
        if (article) {
          article.innerHTML = state.originalContent[articleId];
        }
      });
    } else {
      // Restore page content
      if (state.editableElement && state.originalContent.main) {
        state.editableElement.innerHTML = state.originalContent.main;
      }
      // Restore title
      const titleInput = document.getElementById('editor-title');
      if (titleInput) {
        titleInput.value = state.pageTitle;
      }
    }

    state.isDirty = false;
    updateToolbarState();
    showToast('Changes discarded', 'info');
  }

  // Keyboard shortcuts
  function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // Cmd+S or Ctrl+S to save
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault();
        saveContent();
      }

      // Cmd+B for bold
      if ((e.metaKey || e.ctrlKey) && e.key === 'b') {
        e.preventDefault();
        document.execCommand('bold', false, null);
        markDirty();
      }

      // Cmd+I for italic
      if ((e.metaKey || e.ctrlKey) && e.key === 'i') {
        e.preventDefault();
        document.execCommand('italic', false, null);
        markDirty();
      }

      // Cmd+K for link
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        const url = prompt('Enter URL:');
        if (url) {
          document.execCommand('createLink', false, url);
          markDirty();
        }
      }
    });
  }

  // Before unload warning
  function setupBeforeUnload() {
    window.addEventListener('beforeunload', (e) => {
      if (state.isDirty) {
        e.preventDefault();
        e.returnValue = '';
      }
    });
  }

  // Show toast notification
  function showToast(message, type = 'info') {
    const existing = document.querySelector('.editor-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.className = 'editor-toast editor-toast-' + type;
    toast.textContent = message;
    document.body.appendChild(toast);

    // Trigger animation
    setTimeout(() => toast.classList.add('show'), 10);

    // Auto-remove
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }

  // Escape HTML for safe insertion
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
})();
