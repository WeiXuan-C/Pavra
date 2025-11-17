/**
 * Flutter Plugins Initialization Scripts
 * 
 * Purpose: This file contains initialization code for Flutter plugins that require
 * web-specific setup or configuration. 
 */
(function () {
    // Initialize plugins when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializePlugins);
    } else {
        initializePlugins();
    }
    
    function initializePlugins() {
        console.log('[Flutter Plugins] Initializing web plugins...');
        // Load Google Maps API
        loadGoogleMapsAPI();
        console.log('[Flutter Plugins] Web plugins initialization completed');
    }
    
    function loadGoogleMapsAPI() {
        // Load Google Maps JavaScript API with Places library
        // Note: API key should be injected during build process
        // For now, it will be loaded from a meta tag in index.html
        var apiKey = document.querySelector('meta[name="google-maps-api-key"]')?.content;
        
        if (!apiKey) {
            console.warn('[Google Maps] API key not found in meta tag. Maps may not work.');
            // Fallback to environment-injected key (set during build)
            apiKey = '{{GOOGLE_MAPS_API_KEY}}'; // This will be replaced during build
        }
        
        var script = document.createElement('script');
        script.src = 'https://maps.googleapis.com/maps/api/js?key=' + apiKey + '&libraries=places';
        script.async = true;
        script.defer = true;
        script.onload = function() {
            console.log('[Google Maps] API loaded successfully');
        };
        script.onerror = function() {
            console.error('[Google Maps] Failed to load API');
        };
        document.head.appendChild(script);
    }
})();