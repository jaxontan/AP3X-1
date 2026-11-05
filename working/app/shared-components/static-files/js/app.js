// Flash Concepts APEX Client Enhancements & Accessibility Guard
(function() {
    function fixAriaLabels() {
        document.querySelectorAll('button.t-Button--navBar, button.t-Button--header').forEach(function(btn) {
            var labelEl = btn.querySelector('.t-Button-label');
            var text = labelEl ? labelEl.textContent.trim() : (btn.textContent ? btn.textContent.trim() : '');
            var title = btn.getAttribute('title') || '';
            btn.setAttribute('aria-label', text || title || 'User Account Menu');
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fixAriaLabels);
    } else {
        fixAriaLabels();
    }
    
    if (typeof apex !== 'undefined' && apex.jQuery) {
        apex.jQuery(document).on('apexready', fixAriaLabels);
    }
})();
