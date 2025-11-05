// BijbelQuiz Admin Dashboard App
class AdminDashboard {
    constructor() {
        this.isLoggedIn = false;
        this.currentTab = 'tracking';
        this.trackingData = null;
        this.selectedFeature = null;
        this.selectedError = null;
        this.selectedStoreItem = null;
        this.selectedMessage = null;
        this.chart = null; // For Chart.js

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.showLoginScreen();
    }

    setupEventListeners() {
        // Login form
        document.getElementById('login-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        // Logout button
        document.getElementById('logout-btn').addEventListener('click', () => {
            this.handleLogout();
        });

        // Navigation tabs
        document.querySelectorAll('.navigation a').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const tabId = e.target.getAttribute('data-tab');
                this.switchTab(tabId);
            });
        });

        // Tracking tab events
        document.getElementById('load-tracking-btn').addEventListener('click', () => {
            this.loadTrackingData();
        });
        document.getElementById('apply-filters-btn').addEventListener('click', () => {
            this.applyTrackingFilters();
        });

        // Error reports tab events
        document.getElementById('load-errors-btn').addEventListener('click', () => {
            this.loadErrorReports();
        });
        document.getElementById('clear-filters-btn').addEventListener('click', () => {
            this.clearErrorFilters();
        });
        document.getElementById('delete-error-btn').addEventListener('click', () => {
            this.deleteSelectedError();
        });

        // Store management tab events
        document.getElementById('load-store-btn').addEventListener('click', () => {
            this.loadStoreItems();
        });
        document.getElementById('add-store-item-btn').addEventListener('click', () => {
            this.showAddStoreItemModal();
        });
        document.getElementById('update-item-btn').addEventListener('click', () => {
            this.updateStoreItem();
        });
        document.getElementById('delete-item-btn').addEventListener('click', () => {
            this.deleteStoreItem();
        });
        document.getElementById('is-discounted').addEventListener('change', (e) => {
            this.toggleDiscountFields(e.target.checked);
        });

        // Message management tab events
        document.getElementById('load-messages-btn').addEventListener('click', () => {
            this.loadMessages();
        });
        document.getElementById('add-message-btn').addEventListener('click', () => {
            this.showAddMessageModal();
        });
        document.getElementById('update-message-btn').addEventListener('click', () => {
            this.updateMessage();
        });
        document.getElementById('delete-message-btn').addEventListener('click', () => {
            this.deleteMessage();
        });

        // Modal events
        document.querySelector('#add-store-item-modal .close').addEventListener('click', () => {
            this.hideAddStoreItemModal();
        });
        document.querySelector('#add-message-modal .close').addEventListener('click', () => {
            this.hideAddMessageModal();
        });
        document.getElementById('cancel-new-item').addEventListener('click', () => {
            this.hideAddStoreItemModal();
        });
        document.getElementById('cancel-new-message').addEventListener('click', () => {
            this.hideAddMessageModal();
        });
        document.getElementById('new-is-discounted').addEventListener('change', (e) => {
            document.getElementById('new-discount-fields').style.display = e.target.checked ? 'block' : 'none';
            document.getElementById('new-discount-dates').style.display = e.target.checked ? 'block' : 'none';
        });
        document.getElementById('new-store-item-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addNewStoreItem();
        });
        document.getElementById('new-message-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addNewMessage();
        });

        // Filter events
        document.getElementById('error-type-filter').addEventListener('change', () => {
            this.loadErrorReports();
        });
        document.getElementById('user-filter').addEventListener('input', () => {
            this.loadErrorReports();
        });
        document.getElementById('question-filter').addEventListener('input', () => {
            this.loadErrorReports();
        });
        document.getElementById('item-type-filter').addEventListener('change', () => {
            this.loadStoreItems();
        });
        document.getElementById('store-search').addEventListener('input', () => {
            this.loadStoreItems();
        });
        document.getElementById('message-search').addEventListener('input', () => {
            this.loadMessages();
        });

        // Table selection events
        document.getElementById('features-table-body').addEventListener('click', (e) => {
            const row = e.target.closest('tr');
            if (row) {
                this.selectFeature(row);
            }
        });

        document.getElementById('errors-table-body').addEventListener('click', (e) => {
            const row = e.target.closest('tr');
            if (row) {
                this.selectError(row);
            }
        });

        document.getElementById('store-table-body').addEventListener('click', (e) => {
            const row = e.target.closest('tr');
            if (row) {
                this.selectStoreItem(row);
            }
        });

        document.getElementById('messages-table-body').addEventListener('click', (e) => {
            const row = e.target.closest('tr');
            if (row) {
                this.selectMessage(row);
            }
        });

        // Chart tab events
        document.querySelectorAll('.chart-tabs .tab-btn').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabId = e.target.getAttribute('data-tab');
                this.switchChartTab(tabId);
            });
        });
    }

    // Authentication methods
    showLoginScreen() {
        document.getElementById('login-screen').style.display = 'flex';
        document.getElementById('dashboard').style.display = 'none';
    }

    showDashboard() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('dashboard').style.display = 'block';
    }

    async handleLogin() {
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        try {
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ username, password })
            });

            const data = await response.json();

            if (response.ok) {
                // Store the token in localStorage or sessionStorage
                localStorage.setItem('adminToken', data.token);
                
                this.isLoggedIn = true;
                this.showDashboard();
                // Load initial data after login
                this.switchTab('tracking');
            } else {
                document.getElementById('login-error').style.display = 'block';
                document.getElementById('login-error').textContent = data.error || 'Invalid username or password';
            }
        } catch (error) {
            console.error('Login error:', error);
            document.getElementById('login-error').style.display = 'block';
            document.getElementById('login-error').textContent = 'Network error. Please try again.';
        }
    }

    handleLogout() {
        this.isLoggedIn = false;
        localStorage.removeItem('adminToken'); // Clear the stored token
        this.showLoginScreen();
        
        // Reset form values
        document.getElementById('username').value = '';
        document.getElementById('password').value = '';
    }

    // Tab management
    switchTab(tabId) {
        // Update active tab in navigation
        document.querySelectorAll('.navigation a').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('data-tab') === tabId) {
                link.classList.add('active');
            }
        });

        // Hide all tab content
        document.querySelectorAll('.tab-content').forEach(tab => {
            tab.classList.remove('active');
        });

        // Show selected tab content
        document.getElementById(`${tabId}-tab`).classList.add('active');

        this.currentTab = tabId;

        // Load data for specific tab if needed
        switch(tabId) {
            case 'tracking':
                // Load tracking data if not already loaded
                if (!this.trackingData) {
                    this.loadTrackingData();
                }
                break;
            case 'errors':
                this.loadErrorReports();
                break;
            case 'store':
                this.loadStoreItems();
                break;
            case 'messages':
                this.loadMessages();
                break;
        }
    }

    // Tracking data methods
    async loadTrackingData() {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch('/api/tracking', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                this.trackingData = await response.json();
                this.updateTrackingFilterOptions();
                this.displayFeaturesOverview();
                this.displayTrackingRecords();
            } else {
                const errorData = await response.json();
                console.error('Error loading tracking data:', errorData);
                alert('Failed to load tracking data: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading tracking data:', error);
            alert('Failed to load tracking data');
        }
    }

    updateTrackingFilterOptions() {
        if (!this.trackingData) return;

        const featureFilter = document.getElementById('feature-filter');
        const actionFilter = document.getElementById('action-filter');

        // Clear existing options
        featureFilter.innerHTML = '<option value="">All</option>';
        actionFilter.innerHTML = '<option value="">All</option>';

        // Get unique features
        const features = [...new Set(this.trackingData.map(record => record.event_name))];
        features.forEach(feature => {
            const option = document.createElement('option');
            option.value = feature;
            option.textContent = feature;
            featureFilter.appendChild(option);
        });

        // Get unique actions
        const actions = [...new Set(this.trackingData.map(record => record.event_type))];
        actions.forEach(action => {
            const option = document.createElement('option');
            option.value = action;
            option.textContent = action;
            actionFilter.appendChild(option);
        });
    }

    displayFeaturesOverview() {
        const tbody = document.getElementById('features-table-body');
        tbody.innerHTML = '';

        if (!this.trackingData) return;

        // Group by features and calculate statistics
        const featureStats = this.getFeatureStats();

        featureStats.forEach(stat => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${stat.feature}</td>
                <td>${stat.usageCount}</td>
                <td>${stat.uniqueUsers}</td>
                <td>${stat.lastUsed}</td>
            `;
            tbody.appendChild(row);
        });
    }

    displayTrackingRecords() {
        // This method could be implemented to show detailed tracking records
        // For now, we'll just show a message
        console.log('Displaying tracking records');
    }

    getFeatureStats() {
        if (!this.trackingData) return [];

        const grouped = {};
        this.trackingData.forEach(record => {
            const feature = record.event_name;
            if (!grouped[feature]) {
                grouped[feature] = {
                    feature: feature,
                    usageCount: 0,
                    uniqueUsers: new Set(),
                    lastUsed: record.timestamp
                };
            }
            
            grouped[feature].usageCount++;
            grouped[feature].uniqueUsers.add(record.user_id);
            
            if (record.timestamp > grouped[feature].lastUsed) {
                grouped[feature].lastUsed = record.timestamp;
            }
        });

        return Object.values(grouped).map(stat => ({
            ...stat,
            uniqueUsers: stat.uniqueUsers.size
        }));
    }

    applyTrackingFilters() {
        // In a real implementation, this would filter the data based on the selected filters
        console.log('Applying tracking filters');
        this.displayFeaturesOverview();
    }

    selectFeature(row) {
        // Remove active class from previously selected row
        document.querySelectorAll('#features-table-body tr').forEach(r => {
            r.classList.remove('active');
        });

        // Add active class to selected row
        row.classList.add('active');

        // Get feature name from the first column
        const featureName = row.cells[0].textContent;
        this.selectedFeature = featureName;

        // Display feature details
        this.displayFeatureDetails(featureName);
        this.analyzeFeatureUsage();
        
        // Initialize chart tabs with default time series chart
        this.switchChartTab('time');
    }

    displayFeatureDetails(featureName) {
        const detailsElement = document.getElementById('feature-details');
        detailsElement.innerHTML = `
            <h4>Feature: ${featureName}</h4>
            <p>Select this feature to see detailed analysis</p>
        `;
    }

    analyzeFeatureUsage() {
        if (!this.selectedFeature) return;

        const featureData = this.trackingData.filter(item => item.event_name === this.selectedFeature);

        if (!featureData.length) {
            document.getElementById('feature-stats').innerHTML = `<p>No data found for feature: ${this.selectedFeature}</p>`;
            // Clear the visualization
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
            return;
        }

        // Calculate statistics
        const stats = [];
        stats.push(`Feature: ${this.selectedFeature}`);
        stats.push(`Total Events: ${featureData.length}`);
        stats.push(`Unique Users: ${[...new Set(featureData.map(item => item.user_id))].length}`);

        // Actions breakdown
        const actionCounts = {};
        featureData.forEach(item => {
            actionCounts[item.event_type] = (actionCounts[item.event_type] || 0) + 1;
        });

        stats.push(`<br>Event Type Breakdown:`);
        for (const [action, count] of Object.entries(actionCounts)) {
            stats.push(`  ${action}: ${count}`);
        }

        // Platform breakdown
        const platformCounts = {};
        featureData.forEach(item => {
            if (item.platform) {
                platformCounts[item.platform] = (platformCounts[item.platform] || 0) + 1;
            }
        });

        stats.push(`<br>Platform Breakdown:`);
        for (const [platform, count] of Object.entries(platformCounts)) {
            stats.push(`  ${platform}: ${count}`);
        }

        // App version breakdown
        const versionCounts = {};
        featureData.forEach(item => {
            if (item.app_version) {
                versionCounts[item.app_version] = (versionCounts[item.app_version] || 0) + 1;
            }
        });

        stats.push(`<br>App Version Breakdown:`);
        for (const [version, count] of Object.entries(versionCounts)) {
            stats.push(`  ${version}: ${count}`);
        }

        document.getElementById('feature-stats').innerHTML = `<pre>${stats.join('\n')}</pre>`;
    }

    createVisualization(featureData) {
        // Destroy existing chart if it exists
        if (this.chart) {
            this.chart.destroy();
        }

        // Prepare data for visualization
        // 1. Time series data (events per day)
        const dailyUsage = this.getDailyUsage(featureData);
        const timeLabels = dailyUsage.map(item => item.date);
        const timeData = dailyUsage.map(item => item.count);

        // 2. Platform distribution
        const platformData = this.getPlatformDistribution(featureData);
        const platformLabels = Object.keys(platformData);
        const platformCounts = Object.values(platformData);

        // 3. Event type distribution
        const eventTypeData = this.getEventTypeDistribution(featureData);
        const eventTypeLabels = Object.keys(eventTypeData);
        const eventTypeCounts = Object.values(eventTypeData);

        // Get the canvas context
        const ctx = document.getElementById('visualization-canvas').getContext('2d');
        
        // Create a combined chart with multiple datasets
        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: timeLabels,
                datasets: [
                    {
                        label: 'Daily Events',
                        data: timeData,
                        borderColor: 'rgb(75, 192, 192)',
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        yAxisID: 'y'
                    }
                ]
            },
            options: {
                responsive: true,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                scales: {
                    x: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    },
                    y: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Number of Events'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Feature Usage Over Time'
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false
                    }
                }
            },
            plugins: [{
                id: 'featureDetails',
                beforeDraw: function(chart) {
                    // This plugin adds more detailed information to the chart
                    // For now, we'll just use it to ensure proper rendering
                }
            }]
        });

        // For a more comprehensive view, we could also create additional charts
        // showing different aspects of the data (platform distribution, event types, etc.)
    }

    getDailyUsage(featureData) {
        // Group events by date
        const dailyCounts = {};
        
        featureData.forEach(item => {
            // Extract date from timestamp (assuming format is YYYY-MM-DD HH:MM:SS)
            const date = item.timestamp.split(' ')[0];
            
            if (!dailyCounts[date]) {
                dailyCounts[date] = 0;
            }
            dailyCounts[date]++;
        });

        // Convert to array and sort by date
        return Object.entries(dailyCounts)
            .map(([date, count]) => ({ date, count }))
            .sort((a, b) => new Date(a.date) - new Date(b.date));
    }

    getPlatformDistribution(featureData) {
        const platformCounts = {};
        
        featureData.forEach(item => {
            if (item.platform) {
                if (!platformCounts[item.platform]) {
                    platformCounts[item.platform] = 0;
                }
                platformCounts[item.platform]++;
            }
        });

        return platformCounts;
    }

    getEventTypeDistribution(featureData) {
        const eventTypeCounts = {};
        
        featureData.forEach(item => {
            if (item.event_type) {
                if (!eventTypeCounts[item.event_type]) {
                    eventTypeCounts[item.event_type] = 0;
                }
                eventTypeCounts[item.event_type]++;
            }
        });

        return eventTypeCounts;
    }

    switchChartTab(tabId) {
        // Update active tab button
        document.querySelectorAll('.chart-tabs .tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`.chart-tabs .tab-btn[data-tab="${tabId}"]`).classList.add('active');

        // Get the currently selected feature data
        if (this.selectedFeature && this.trackingData) {
            const featureData = this.trackingData.filter(item => item.event_name === this.selectedFeature);
            this.renderChart(tabId, featureData);
        }
    }

    renderChart(chartType, featureData) {
        // Destroy existing chart if it exists
        if (this.chart) {
            this.chart.destroy();
        }

        const ctx = document.getElementById('visualization-canvas').getContext('2d');
        
        switch(chartType) {
            case 'time':
                this.renderTimeSeriesChart(ctx, featureData);
                break;
            case 'platform':
                this.renderPlatformDistributionChart(ctx, featureData);
                break;
            case 'event-type':
                this.renderEventTypeChart(ctx, featureData);
                break;
            default:
                this.renderTimeSeriesChart(ctx, featureData);
        }
    }

    renderTimeSeriesChart(ctx, featureData) {
        // Prepare data for time series chart
        const dailyUsage = this.getDailyUsage(featureData);
        const timeLabels = dailyUsage.map(item => item.date);
        const timeData = dailyUsage.map(item => item.count);

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: timeLabels,
                datasets: [{
                    label: 'Daily Events',
                    data: timeData,
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    },
                    y: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Number of Events'
                        },
                        beginAtZero: true
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Feature Usage Over Time'
                    },
                    legend: {
                        display: true,
                        position: 'top',
                    }
                }
            }
        });
    }

    renderPlatformDistributionChart(ctx, featureData) {
        // Prepare data for platform distribution chart
        const platformData = this.getPlatformDistribution(featureData);
        const platformLabels = Object.keys(platformData);
        const platformCounts = Object.values(platformData);

        this.chart = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: platformLabels,
                datasets: [{
                    label: 'Platform Distribution',
                    data: platformCounts,
                    backgroundColor: [
                        'rgba(255, 99, 132, 0.7)',
                        'rgba(54, 162, 235, 0.7)',
                        'rgba(255, 206, 86, 0.7)',
                        'rgba(75, 192, 192, 0.7)',
                        'rgba(153, 102, 255, 0.7)',
                        'rgba(255, 159, 64, 0.7)'
                    ],
                    borderColor: [
                        'rgba(255, 99, 132, 1)',
                        'rgba(54, 162, 235, 1)',
                        'rgba(255, 206, 86, 1)',
                        'rgba(75, 192, 192, 1)',
                        'rgba(153, 102, 255, 1)',
                        'rgba(255, 159, 64, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        display: true,
                        text: 'Platform Distribution'
                    },
                    legend: {
                        display: true,
                        position: 'bottom',
                    }
                }
            }
        });
    }

    renderEventTypeChart(ctx, featureData) {
        // Prepare data for event type chart
        const eventTypeData = this.getEventTypeDistribution(featureData);
        const eventTypeLabels = Object.keys(eventTypeData);
        const eventTypeCounts = Object.values(eventTypeData);

        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: eventTypeLabels,
                datasets: [{
                    label: 'Event Count',
                    data: eventTypeCounts,
                    backgroundColor: 'rgba(54, 162, 235, 0.7)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                indexAxis: 'y', // Horizontal bar chart
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Number of Events'
                        },
                        beginAtZero: true
                    },
                    y: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Event Type'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Event Type Distribution'
                    },
                    legend: {
                        display: false
                    }
                }
            }
        });
    }

    // Error reports methods
    async loadErrorReports() {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            // Get filter values
            const errorTypeFilter = document.getElementById('error-type-filter').value;
            const userFilter = document.getElementById('user-filter').value;
            const questionFilter = document.getElementById('question-filter').value;

            // Build query string with filters
            const params = new URLSearchParams();
            if (errorTypeFilter) params.append('type', errorTypeFilter);
            if (userFilter) params.append('user', userFilter);
            if (questionFilter) params.append('question', questionFilter);

            const queryString = params.toString();
            const url = queryString ? `/api/errors?${queryString}` : '/api/errors';

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const errorReports = await response.json();

                // Update the table
                const tbody = document.getElementById('errors-table-body');
                tbody.innerHTML = '';

                errorReports.forEach(error => {
                    const row = document.createElement('tr');
                    
                    // Truncate error message
                    let errorMessage = error.user_message || error.error_message;
                    if (errorMessage.length > 50) {
                        errorMessage = errorMessage.substring(0, 50) + '...';
                    }
                    
                    row.innerHTML = `
                        <td>${error.timestamp}</td>
                        <td>${error.error_type}</td>
                        <td>${error.user_id}</td>
                        <td>${error.question_id || ''}</td>
                        <td>${errorMessage}</td>
                    `;
                    row.dataset.errorId = error.id; // Store error ID in data attribute
                    tbody.appendChild(row);
                });

                console.log(`Loaded ${errorReports.length} error reports`);
            } else {
                const errorData = await response.json();
                console.error('Error loading error reports:', errorData);
                alert('Failed to load error reports: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading error reports:', error);
            alert('Failed to load error reports');
        }
    }

    clearErrorFilters() {
        document.getElementById('error-type-filter').value = '';
        document.getElementById('user-filter').value = '';
        document.getElementById('question-filter').value = '';
        this.loadErrorReports();
    }

    selectError(row) {
        // Remove active class from previously selected row
        document.querySelectorAll('#errors-table-body tr').forEach(r => {
            r.classList.remove('active');
        });

        // Add active class to selected row
        row.classList.add('active');

        // Get error ID from data attribute
        const errorId = row.dataset.errorId;
        this.selectedError = errorId;

        // Display error details
        this.displayErrorDetails(errorId);
    }

    async displayErrorDetails(errorId) {
        // Fetch the specific error details from the API
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch(`/api/errors/${errorId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const errorDetails = await response.json();

                const detailsElement = document.getElementById('error-details');
                detailsElement.innerHTML = `
                    <h4>Error #${errorDetails.id}</h4>
                    <p><strong>Timestamp:</strong> ${errorDetails.timestamp}</p>
                    <p><strong>Error Type:</strong> ${errorDetails.error_type}</p>
                    <p><strong>User ID:</strong> ${errorDetails.user_id}</p>
                    <p><strong>Question ID:</strong> ${errorDetails.question_id || 'N/A'}</p>
                    <p><strong>User Message:</strong> ${errorDetails.user_message || 'N/A'}</p>
                    <p><strong>Technical Message:</strong> ${errorDetails.error_message || 'N/A'}</p>
                    <p><strong>Error Code:</strong> ${errorDetails.error_code || 'N/A'}</p>
                    <p><strong>Context:</strong> ${errorDetails.context || 'N/A'}</p>
                    <p><strong>Additional Info:</strong> ${errorDetails.additional_info || 'N/A'}</p>
                    <p><strong>Stack Trace:</strong> ${errorDetails.stack_trace || 'N/A'}</p>
                    <p><strong>Device Info:</strong> ${errorDetails.device_info || 'N/A'}</p>
                    <p><strong>App Version:</strong> ${errorDetails.app_version || 'N/A'}</p>
                    <p><strong>Build Number:</strong> ${errorDetails.build_number || 'N/A'}</p>
                `;
            } else {
                const errorData = await response.json();
                console.error('Error fetching error details:', errorData);
                document.getElementById('error-details').innerHTML = `<p>Error loading details: ${errorData.error}</p>`;
            }
        } catch (error) {
            console.error('Error fetching error details:', error);
            document.getElementById('error-details').innerHTML = `<p>Error loading details: ${error.message}</p>`;
        }
    }

    async deleteSelectedError() {
        if (!this.selectedError) {
            alert('Please select an error to delete');
            return;
        }

        if (confirm(`Are you sure you want to delete error report #${this.selectedError}? This action cannot be undone.`)) {
            try {
                const token = localStorage.getItem('adminToken');
                if (!token) {
                    this.showLoginScreen();
                    return;
                }

                const response = await fetch(`/api/errors/${this.selectedError}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (response.ok) {
                    alert(`Error report #${this.selectedError} has been deleted successfully.`);
                    this.loadErrorReports();
                    document.getElementById('error-details').innerHTML = '<p>Select an error to view details</p>';
                } else {
                    const errorData = await response.json();
                    console.error('Error deleting error report:', errorData);
                    alert('Failed to delete error report: ' + errorData.error);
                }
            } catch (error) {
                console.error('Error deleting error report:', error);
                alert('Failed to delete error report');
            }
        }
    }

    // Store management methods
    async loadStoreItems() {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            // Get filter values
            const itemTypeFilter = document.getElementById('item-type-filter').value;
            const searchFilter = document.getElementById('store-search').value;

            // Build query string with filters
            const params = new URLSearchParams();
            if (itemTypeFilter) params.append('type', itemTypeFilter);
            if (searchFilter) params.append('search', searchFilter);

            const queryString = params.toString();
            const url = queryString ? `/api/store?${queryString}` : '/api/store';

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const storeItems = await response.json();

                // Update the table
                const tbody = document.getElementById('store-table-body');
                tbody.innerHTML = '';

                storeItems.forEach(item => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${item.item_key}</td>
                        <td>${item.item_name}</td>
                        <td>${item.item_type}</td>
                        <td>${item.base_price}</td>
                        <td>${item.current_price}</td>
                        <td>${item.is_discounted ? 'Yes' : 'No'}</td>
                    `;
                    row.dataset.itemId = item.id; // Store item ID in data attribute
                    tbody.appendChild(row);
                });

                console.log(`Loaded ${storeItems.length} store items`);
            } else {
                const errorData = await response.json();
                console.error('Error loading store items:', errorData);
                alert('Failed to load store items: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading store items:', error);
            alert('Failed to load store items');
        }
    }

    selectStoreItem(row) {
        // Remove active class from previously selected row
        document.querySelectorAll('#store-table-body tr').forEach(r => {
            r.classList.remove('active');
        });

        // Add active class to selected row
        row.classList.add('active');

        // Get item ID from data attribute
        const itemId = row.dataset.itemId;
        this.selectedStoreItem = itemId;

        // Load item details into form
        this.loadStoreItemDetails(itemId);
    }

    async loadStoreItemDetails(itemId) {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch(`/api/store/${itemId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const storeItem = await response.json();

                // Update form fields with item details
                document.getElementById('item-key').value = storeItem.item_key;
                document.getElementById('item-name').value = storeItem.item_name;
                document.getElementById('item-description').value = storeItem.item_description;
                document.getElementById('item-type').value = storeItem.item_type;
                document.getElementById('icon').value = storeItem.icon;
                document.getElementById('base-price').value = storeItem.base_price;
                document.getElementById('category').value = storeItem.category;
                document.getElementById('is-active').checked = storeItem.is_active;
                
                const isDiscountedCheckbox = document.getElementById('is-discounted');
                isDiscountedCheckbox.checked = storeItem.is_discounted;
                this.toggleDiscountFields(storeItem.is_discounted);
                
                document.getElementById('discount-percentage').value = storeItem.discount_percentage || 0;

                // Format discount dates
                if (storeItem.discount_start) {
                    // Convert to datetime-local format (YYYY-MM-DDTHH:mm format)
                    const startDate = new Date(storeItem.discount_start);
                    document.getElementById('discount-start').value = startDate.toISOString().slice(0, 16);
                } else {
                    document.getElementById('discount-start').value = '';
                }

                if (storeItem.discount_end) {
                    // Convert to datetime-local format (YYYY-MM-DDTHH:mm format)
                    const endDate = new Date(storeItem.discount_end);
                    document.getElementById('discount-end').value = endDate.toISOString().slice(0, 16);
                } else {
                    document.getElementById('discount-end').value = '';
                }
            } else {
                const errorData = await response.json();
                console.error('Error loading store item details:', errorData);
                alert('Failed to load store item details: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading store item details:', error);
            alert('Failed to load store item details');
        }
    }

    toggleDiscountFields(isDiscounted) {
        const discountFields = document.getElementById('discount-fields');
        const discountDates = document.getElementById('discount-dates');
        
        discountFields.style.display = isDiscounted ? 'block' : 'none';
        discountDates.style.display = isDiscounted ? 'block' : 'none';
    }

    async updateStoreItem() {
        if (!this.selectedStoreItem) {
            alert('Please select a store item to update');
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            // Get form values
            const updateData = {
                item_name: document.getElementById('item-name').value,
                item_description: document.getElementById('item-description').value,
                item_type: document.getElementById('item-type').value,
                icon: document.getElementById('icon').value,
                base_price: parseInt(document.getElementById('base-price').value) || 0,
                category: document.getElementById('category').value,
                is_active: document.getElementById('is-active').checked,
                is_discounted: document.getElementById('is-discounted').checked,
                discount_percentage: parseInt(document.getElementById('discount-percentage').value) || 0,
            };

            // Add date fields if discounted
            if (document.getElementById('is-discounted').checked) {
                updateData.discount_start = document.getElementById('discount-start').value;
                updateData.discount_end = document.getElementById('discount-end').value;
            }

            const response = await fetch(`/api/store/${this.selectedStoreItem}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(updateData)
            });

            if (response.ok) {
                alert('Store item updated successfully');
                this.loadStoreItems();
            } else {
                const errorData = await response.json();
                console.error('Error updating store item:', errorData);
                alert('Failed to update store item: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error updating store item:', error);
            alert('Failed to update store item');
        }
    }

    async deleteStoreItem() {
        if (!this.selectedStoreItem) {
            alert('Please select a store item to delete');
            return;
        }

        if (confirm(`Are you sure you want to delete store item #${this.selectedStoreItem}? This action cannot be undone.`)) {
            try {
                const token = localStorage.getItem('adminToken');
                if (!token) {
                    this.showLoginScreen();
                    return;
                }

                const response = await fetch(`/api/store/${this.selectedStoreItem}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (response.ok) {
                    alert(`Store item #${this.selectedStoreItem} has been deleted successfully.`);
                    this.loadStoreItems();
                    this.resetStoreItemForm();
                } else {
                    const errorData = await response.json();
                    console.error('Error deleting store item:', errorData);
                    alert('Failed to delete store item: ' + errorData.error);
                }
            } catch (error) {
                console.error('Error deleting store item:', error);
                alert('Failed to delete store item');
            }
        }
    }

    showAddStoreItemModal() {
        document.getElementById('add-store-item-modal').style.display = 'block';
    }

    hideAddStoreItemModal() {
        document.getElementById('add-store-item-modal').style.display = 'none';
        this.resetNewStoreItemForm();
    }

    resetNewStoreItemForm() {
        document.getElementById('new-item-key').value = '';
        document.getElementById('new-item-name').value = '';
        document.getElementById('new-item-description').value = '';
        document.getElementById('new-item-type').value = 'powerup';
        document.getElementById('new-icon').value = '';
        document.getElementById('new-base-price').value = '0';
        document.getElementById('new-category').value = '';
        document.getElementById('new-is-active').checked = true;
        document.getElementById('new-is-discounted').checked = false;
        document.getElementById('new-discount-fields').style.display = 'none';
        document.getElementById('new-discount-dates').style.display = 'none';
        document.getElementById('new-discount-percentage').value = '0';
        document.getElementById('new-discount-start').value = '';
        document.getElementById('new-discount-end').value = '';
    }

    async addNewStoreItem() {
        // Get form values
        const newItem = {
            item_key: document.getElementById('new-item-key').value,
            item_name: document.getElementById('new-item-name').value,
            item_description: document.getElementById('new-item-description').value,
            item_type: document.getElementById('new-item-type').value,
            icon: document.getElementById('new-icon').value,
            base_price: parseInt(document.getElementById('new-base-price').value) || 0,
            category: document.getElementById('new-category').value,
            is_active: document.getElementById('new-is-active').checked,
            is_discounted: document.getElementById('new-is-discounted').checked,
            discount_percentage: parseInt(document.getElementById('new-discount-percentage').value) || 0,
        };

        // Add date fields if discounted
        if (document.getElementById('new-is-discounted').checked) {
            newItem.discount_start = document.getElementById('new-discount-start').value;
            newItem.discount_end = document.getElementById('new-discount-end').value;
        }

        // Validate required fields
        if (!newItem.item_key || !newItem.item_name) {
            alert('Item key and name are required');
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch('/api/store', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(newItem)
            });

            if (response.ok) {
                alert('Store item added successfully');
                
                // Close modal and refresh list
                this.hideAddStoreItemModal();
                this.loadStoreItems();
            } else {
                const errorData = await response.json();
                console.error('Error adding store item:', errorData);
                alert('Failed to add store item: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error adding store item:', error);
            alert('Failed to add store item');
        }
    }

    resetStoreItemForm() {
        document.getElementById('item-key').value = '';
        document.getElementById('item-name').value = '';
        document.getElementById('item-description').value = '';
        document.getElementById('item-type').value = 'powerup';
        document.getElementById('icon').value = '';
        document.getElementById('base-price').value = '0';
        document.getElementById('category').value = '';
        document.getElementById('is-active').checked = true;
        document.getElementById('is-discounted').checked = false;
        this.toggleDiscountFields(false);
        document.getElementById('discount-percentage').value = '0';
        document.getElementById('discount-start').value = '';
        document.getElementById('discount-end').value = '';
    }

    // Message management methods
    async loadMessages() {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            // Get search filter
            const searchFilter = document.getElementById('message-search').value;

            // Build query string with search filter
            const params = new URLSearchParams();
            if (searchFilter) params.append('search', searchFilter);

            const queryString = params.toString();
            const url = queryString ? `/api/messages?${queryString}` : '/api/messages';

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const messages = await response.json();

                // Update the table
                const tbody = document.getElementById('messages-table-body');
                tbody.innerHTML = '';

                messages.forEach(message => {
                    // Truncate content
                    let content = message.content;
                    if (content.length > 30) {
                        content = content.substring(0, 30) + '...';
                    }
                    
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${message.id}</td>
                        <td>${message.title}</td>
                        <td>${content}</td>
                        <td>${message.expiration_date}</td>
                        <td>${message.created_at}</td>
                    `;
                    row.dataset.messageId = message.id; // Store message ID in data attribute
                    tbody.appendChild(row);
                });

                console.log(`Loaded ${messages.length} messages`);
            } else {
                const errorData = await response.json();
                console.error('Error loading messages:', errorData);
                alert('Failed to load messages: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading messages:', error);
            alert('Failed to load messages');
        }
    }

    selectMessage(row) {
        // Remove active class from previously selected row
        document.querySelectorAll('#messages-table-body tr').forEach(r => {
            r.classList.remove('active');
        });

        // Add active class to selected row
        row.classList.add('active');

        // Get message ID from data attribute
        const messageId = row.dataset.messageId;
        this.selectedMessage = messageId;

        // Load message details into form
        this.loadMessageDetails(messageId);
    }

    async loadMessageDetails(messageId) {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch(`/api/messages/${messageId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                const message = await response.json();

                // Update form fields with message details
                document.getElementById('message-id').value = message.id;
                document.getElementById('message-title').value = message.title;
                document.getElementById('message-content').value = message.content;
                
                // Format expiration date to datetime-local format (remove seconds for proper input format)
                if (message.expiration_date) {
                    const expDate = new Date(message.expiration_date);
                    const formattedExpDate = expDate.toISOString().slice(0, 16);
                    document.getElementById('expiration-date').value = formattedExpDate;
                } else {
                    document.getElementById('expiration-date').value = '';
                }
                
                document.getElementById('created-at').value = message.created_at || '';

            } else {
                const errorData = await response.json();
                console.error('Error loading message details:', errorData);
                alert('Failed to load message details: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error loading message details:', error);
            alert('Failed to load message details');
        }
    }

    async updateMessage() {
        if (!this.selectedMessage) {
            alert('Please select a message to update');
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            // Get form values
            const updateData = {
                title: document.getElementById('message-title').value,
                content: document.getElementById('message-content').value,
                expiration_date: document.getElementById('expiration-date').value
            };

            const response = await fetch(`/api/messages/${this.selectedMessage}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(updateData)
            });

            if (response.ok) {
                alert('Message updated successfully');
                this.loadMessages();
            } else {
                const errorData = await response.json();
                console.error('Error updating message:', errorData);
                alert('Failed to update message: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error updating message:', error);
            alert('Failed to update message');
        }
    }

    async deleteMessage() {
        if (!this.selectedMessage) {
            alert('Please select a message to delete');
            return;
        }

        if (confirm(`Are you sure you want to delete message #${this.selectedMessage}? This action cannot be undone.`)) {
            try {
                const token = localStorage.getItem('adminToken');
                if (!token) {
                    this.showLoginScreen();
                    return;
                }

                const response = await fetch(`/api/messages/${this.selectedMessage}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (response.ok) {
                    alert(`Message #${this.selectedMessage} has been deleted successfully.`);
                    this.loadMessages();
                    this.resetMessageForm();
                } else {
                    const errorData = await response.json();
                    console.error('Error deleting message:', errorData);
                    alert('Failed to delete message: ' + errorData.error);
                }
            } catch (error) {
                console.error('Error deleting message:', error);
                alert('Failed to delete message');
            }
        }
    }

    showAddMessageModal() {
        document.getElementById('add-message-modal').style.display = 'block';
    }

    hideAddMessageModal() {
        document.getElementById('add-message-modal').style.display = 'none';
        this.resetNewMessageForm();
    }

    resetNewMessageForm() {
        document.getElementById('new-message-title').value = '';
        document.getElementById('new-message-content').value = '';
        document.getElementById('new-expiration-date').value = '';
    }

    async addNewMessage() {
        // Get form values
        const newMessage = {
            title: document.getElementById('new-message-title').value,
            content: document.getElementById('new-message-content').value,
            expiration_date: document.getElementById('new-expiration-date').value
        };

        // Validate required fields
        if (!newMessage.title || !newMessage.content || !newMessage.expiration_date) {
            alert('Title, content, and expiration date are required');
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showLoginScreen();
                return;
            }

            const response = await fetch('/api/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(newMessage)
            });

            if (response.ok) {
                alert('Message added successfully');
                
                // Close modal and refresh list
                this.hideAddMessageModal();
                this.loadMessages();
            } else {
                const errorData = await response.json();
                console.error('Error adding message:', errorData);
                alert('Failed to add message: ' + errorData.error);
            }
        } catch (error) {
            console.error('Error adding message:', error);
            alert('Failed to add message');
        }
    }

    resetMessageForm() {
        document.getElementById('message-id').value = '';
        document.getElementById('message-title').value = '';
        document.getElementById('message-content').value = '';
        document.getElementById('expiration-date').value = '';
        document.getElementById('created-at').value = '';
    }
}

// Initialize the app when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new AdminDashboard();
});