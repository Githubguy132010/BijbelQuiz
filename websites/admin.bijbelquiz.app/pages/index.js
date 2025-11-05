import Head from 'next/head';
import Script from 'next/script';

export default function Home() {
  return (
    <div>
      <Head>
        <title>BijbelQuiz Admin Dashboard</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <link rel="stylesheet" href="/styles.css" />
      </Head>

      <div id="login-container" className="auth-container">
        <div className="login-form">
          <h1>BijbelQuiz Admin Login</h1>
          <form id="auth-form">
            <div className="input-group">
              <label htmlFor="password">Admin Password:</label>
              <input type="password" id="password" name="password" required />
            </div>
            <button type="submit" id="auth-btn">Login</button>
            <div id="auth-error" className="error-message"></div>
          </form>
        </div>
      </div>

      <div id="dashboard-container" className="dashboard-container" style={{ display: 'none' }}>
        <header>
          <h1>BijbelQuiz Admin Dashboard</h1>
          <button id="logout-btn" className="logout-btn">Logout</button>
        </header>

        <nav className="tab-navigation">
          <ul>
            <li><a href="#" data-tab="tracking" className="tab-link active">Tracking Data</a></li>
            <li><a href="#" data-tab="errors" className="tab-link">Error Reports</a></li>
            <li><a href="#" data-tab="store" className="tab-link">Store Management</a></li>
            <li><a href="#" data-tab="messages" className="tab-link">Message Management</a></li>
          </ul>
        </nav>

        <div className="tab-content">
          {/* Tracking Data Tab */}
          <div id="tracking-tab" className="tab-pane active">
            <div className="controls-section">
              <button id="load-tracking-data" className="btn btn-primary">Load Tracking Data</button>
              <div className="filter-controls">
                <select id="feature-filter">
                  <option value="">All Features</option>
                </select>
                <select id="action-filter">
                  <option value="">All Actions</option>
                </select>
                <input type="date" id="date-from" />
                <input type="date" id="date-to" />
                <button id="apply-filters" className="btn btn-secondary">Apply Filters</button>
              </div>
            </div>
            
            <div className="content-grid">
              <div className="left-panel">
                <h3>Features Overview</h3>
                <div className="features-table-container">
                  <table id="features-table" className="data-table">
                    <thead>
                      <tr>
                        <th>Feature</th>
                        <th>Total Usage</th>
                        <th>Unique Users</th>
                        <th>Last Used</th>
                      </tr>
                    </thead>
                    <tbody id="features-table-body">
                      {/* Data will be loaded here */}
                    </tbody>
                  </table>
                </div>
              </div>
              
              <div className="right-panel">
                <div className="feature-details">
                  <h3>Feature Details</h3>
                  <div id="feature-details-content" className="details-content">
                    Select a feature to view details
                  </div>
                </div>
                
                <div className="feature-analysis">
                  <h3>Feature Usage Breakdown</h3>
                  <div id="feature-stats-content" className="stats-content">
                    <button id="analyze-feature" className="btn btn-secondary">Analyze Feature</button>
                    <div id="feature-stats-display"></div>
                  </div>
                </div>
                
                <div className="feature-visualization">
                  <h3>Feature Usage Visualization</h3>
                  <div id="visualization-container">
                    <canvas id="feature-usage-chart"></canvas>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Error Reports Tab */}
          <div id="errors-tab" className="tab-pane">
            <div className="controls-section">
              <button id="load-error-reports" className="btn btn-primary">Load Error Reports</button>
              <div className="filter-controls">
                <select id="error-type-filter">
                  <option value="">All Error Types</option>
                </select>
                <input type="text" id="user-id-filter" placeholder="User ID" />
                <input type="text" id="question-id-filter" placeholder="Question ID" />
                <button id="clear-error-filters" className="btn btn-secondary">Clear Filters</button>
                <button id="delete-selected-error" className="btn btn-danger">Delete Selected</button>
              </div>
            </div>
            
            <div className="content-grid">
              <div className="left-panel">
                <h3>Error Reports</h3>
                <div className="errors-table-container">
                  <table id="errors-table" className="data-table">
                    <thead>
                      <tr>
                        <th>Timestamp</th>
                        <th>Type</th>
                        <th>User ID</th>
                        <th>Question ID</th>
                        <th>Error Message</th>
                      </tr>
                    </thead>
                    <tbody id="errors-table-body">
                      {/* Data will be loaded here */}
                    </tbody>
                  </table>
                </div>
              </div>
              
              <div className="right-panel">
                <h3>Error Details</h3>
                <div id="error-details-content" className="details-content">
                  Select an error to view details
                </div>
              </div>
            </div>
          </div>

          {/* Store Management Tab */}
          <div id="store-tab" className="tab-pane">
            <div className="controls-section">
              <button id="load-store-items" className="btn btn-primary">Load Store Items</button>
              <button id="add-new-store-item" className="btn btn-secondary">Add New Item</button>
              <div className="filter-controls">
                <select id="item-type-filter">
                  <option value="">All Types</option>
                  <option value="powerup">Powerup</option>
                  <option value="theme">Theme</option>
                  <option value="feature">Feature</option>
                </select>
                <input type="text" id="store-search" placeholder="Search items..." />
              </div>
            </div>
            
            <div className="content-grid">
              <div className="left-panel">
                <h3>Store Items</h3>
                <div className="store-table-container">
                  <table id="store-table" className="data-table">
                    <thead>
                      <tr>
                        <th>Item Key</th>
                        <th>Name</th>
                        <th>Type</th>
                        <th>Base Price</th>
                        <th>Current Price</th>
                        <th>Discounted</th>
                      </tr>
                    </thead>
                    <tbody id="store-table-body">
                      {/* Data will be loaded here */}
                    </tbody>
                  </table>
                </div>
              </div>
              
              <div className="right-panel">
                <h3>Item Details</h3>
                <form id="store-item-form" className="store-item-form">
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="item-key">Item Key:</label>
                      <input type="text" id="item-key" readOnly />
                    </div>
                    <div className="form-group">
                      <label htmlFor="item-name">Name:</label>
                      <input type="text" id="item-name" required />
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="item-description">Description:</label>
                      <input type="text" id="item-description" />
                    </div>
                    <div className="form-group">
                      <label htmlFor="item-type">Type:</label>
                      <select id="item-type">
                        <option value="powerup">Powerup</option>
                        <option value="theme">Theme</option>
                        <option value="feature">Feature</option>
                      </select>
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="icon">Icon:</label>
                      <input type="text" id="icon" />
                    </div>
                    <div className="form-group">
                      <label htmlFor="base-price">Base Price:</label>
                      <input type="number" id="base-price" />
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="category">Category:</label>
                      <input type="text" id="category" />
                    </div>
                    <div className="form-group">
                      <label htmlFor="is-active">Is Active:</label>
                      <input type="checkbox" id="is-active" />
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="current-price">Current Price:</label>
                      <input type="number" id="current-price" readOnly />
                    </div>
                    <div className="form-group">
                      <label htmlFor="is-discounted">Is Discounted:</label>
                      <input type="checkbox" id="is-discounted" />
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="discount-percentage">Discount %:</label>
                      <input type="number" id="discount-percentage" />
                    </div>
                    <div className="form-group">
                      <label htmlFor="discount-start">Discount Start:</label>
                      <input type="datetime-local" id="discount-start" />
                    </div>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="discount-end">Discount End:</label>
                      <input type="datetime-local" id="discount-end" />
                    </div>
                  </div>
                  
                  <div className="form-actions">
                    <button type="submit" className="btn btn-primary">Update Item</button>
                    <button type="button" id="delete-store-item" className="btn btn-danger">Delete Item</button>
                  </div>
                </form>
              </div>
            </div>
          </div>

          {/* Message Management Tab */}
          <div id="messages-tab" className="tab-pane">
            <div className="controls-section">
              <button id="load-messages" className="btn btn-primary">Load Messages</button>
              <button id="add-new-message" className="btn btn-secondary">Add New Message</button>
              <div className="filter-controls">
                <input type="text" id="message-search" placeholder="Search messages..." />
              </div>
            </div>
            
            <div className="content-grid">
              <div className="left-panel">
                <h3>Messages</h3>
                <div className="messages-table-container">
                  <table id="messages-table" className="data-table">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Content</th>
                        <th>Expiration Date</th>
                        <th>Created At</th>
                      </tr>
                    </thead>
                    <tbody id="messages-table-body">
                      {/* Data will be loaded here */}
                    </tbody>
                  </table>
                </div>
              </div>
              
              <div className="right-panel">
                <h3>Message Details</h3>
                <form id="message-form" className="message-form">
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="message-id">ID:</label>
                      <input type="text" id="message-id" readOnly />
                    </div>
                    <div className="form-group">
                      <label htmlFor="message-title">Title:</label>
                      <input type="text" id="message-title" required />
                    </div>
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="message-content">Content:</label>
                    <textarea id="message-content" required></textarea>
                  </div>
                  
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="expiration-date">Expiration Date:</label>
                      <input type="datetime-local" id="expiration-date" required />
                    </div>
                    <div className="form-group">
                      <label htmlFor="message-created-at">Created At:</label>
                      <input type="text" id="message-created-at" readOnly />
                    </div>
                  </div>
                  
                  <div className="form-actions">
                    <button type="submit" className="btn btn-primary">Update Message</button>
                    <button type="button" id="delete-message" className="btn btn-danger">Delete Message</button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal for adding new store item */}
      <div id="add-store-modal" className="modal" style={{ display: 'none' }}>
        <div className="modal-content">
          <span className="close">&times;</span>
          <h2>Add New Store Item</h2>
          <form id="add-store-form">
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-item-key">Item Key:</label>
                <input type="text" id="add-item-key" required />
              </div>
              <div className="form-group">
                <label htmlFor="add-item-name">Name:</label>
                <input type="text" id="add-item-name" required />
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-item-description">Description:</label>
                <input type="text" id="add-item-description" />
              </div>
              <div className="form-group">
                <label htmlFor="add-item-type">Type:</label>
                <select id="add-item-type">
                  <option value="powerup">Powerup</option>
                  <option value="theme">Theme</option>
                  <option value="feature">Feature</option>
                </select>
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-icon">Icon:</label>
                <input type="text" id="add-icon" />
              </div>
              <div className="form-group">
                <label htmlFor="add-base-price">Base Price:</label>
                <input type="number" id="add-base-price" />
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-category">Category:</label>
                <input type="text" id="add-category" />
              </div>
              <div className="form-group">
                <label htmlFor="add-is-active">Is Active:</label>
                <input type="checkbox" id="add-is-active" defaultChecked />
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-is-discounted">Is Discounted:</label>
                <input type="checkbox" id="add-is-discounted" />
              </div>
              <div className="form-group">
                <label htmlFor="add-discount-percentage">Discount %:</label>
                <input type="number" id="add-discount-percentage" disabled />
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-discount-start">Discount Start:</label>
                <input type="datetime-local" id="add-discount-start" disabled />
              </div>
              <div className="form-group">
                <label htmlFor="add-discount-end">Discount End:</label>
                <input type="datetime-local" id="add-discount-end" disabled />
              </div>
            </div>
            
            <div className="form-actions">
              <button type="submit" className="btn btn-primary">Save Item</button>
              <button type="button" className="btn btn-secondary cancel-btn">Cancel</button>
            </div>
          </form>
        </div>
      </div>

      {/* Modal for adding new message */}
      <div id="add-message-modal" className="modal" style={{ display: 'none' }}>
        <div className="modal-content">
          <span className="close">&times;</span>
          <h2>Add New Message</h2>
          <form id="add-message-form">
            <div className="form-group">
              <label htmlFor="add-message-title">Title:</label>
              <input type="text" id="add-message-title" required />
            </div>
            
            <div className="form-group">
              <label htmlFor="add-message-content">Content:</label>
              <textarea id="add-message-content" required></textarea>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="add-expiration-date">Expiration Date:</label>
                <input type="datetime-local" id="add-expiration-date" required />
              </div>
            </div>
            
            <div className="form-actions">
              <button type="submit" className="btn btn-primary">Save Message</button>
              <button type="button" className="btn btn-secondary cancel-btn">Cancel</button>
            </div>
          </form>
        </div>
      </div>
      <Script src="https://cdn.jsdelivr.net/npm/chart.js" />
      <Script src="/script.js" />
    </div>
  );
}