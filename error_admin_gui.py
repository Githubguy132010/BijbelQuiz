"""
Admin GUI for viewing reported errors from BijbelQuiz app
Requires: pip install supabase python-dotenv tkinter
"""
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import json
from datetime import datetime
from supabase import create_client, Client
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class ErrorReportingAdminGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("BijbelQuiz Error Reporting Admin")
        self.root.geometry("1200x800")
        
        # Supabase client - only initialize if credentials are available
        self.supabase_client = None
        self.initialize_supabase()
        
        self.setup_ui()
        self.load_errors()
    
    def initialize_supabase(self):
        """Initialize Supabase client using environment variables"""
        try:
            url = os.getenv('SUPABASE_URL')
            key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Should use service role key for admin access
            
            if not url or not key:
                messagebox.showerror("Error", "Supabase credentials not found in environment variables.\n\nPlease set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your .env file.")
                return
            
            self.supabase_client = create_client(url, key)
            # Test connection
            self.test_connection()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to Supabase: {str(e)}")
            self.supabase_client = None
    
    def test_connection(self):
        """Test the Supabase connection"""
        try:
            # Try to fetch a small sample to test connection
            response = self.supabase_client.table('error_reports').select('id').limit(1).execute()
            print("Supabase connection successful")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Could not connect to Supabase: {str(e)}")
            self.supabase_client = None
    
    def setup_ui(self):
        """Setup the user interface"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights for resizing
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(1, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="BijbelQuiz Error Reports", font=("Arial", 16, "bold"))
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 10), sticky=tk.W)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        self.refresh_btn = ttk.Button(button_frame, text="Refresh", command=self.load_errors)
        self.refresh_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        self.clear_filter_btn = ttk.Button(button_frame, text="Clear Filters", command=self.clear_filters)
        self.clear_filter_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        # Filters
        filter_frame = ttk.LabelFrame(main_frame, text="Filters", padding="5")
        filter_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(filter_frame, text="Error Type:").grid(row=0, column=0, padx=(0, 5), sticky=tk.W)
        self.type_filter = ttk.Combobox(filter_frame, values=[
            "", "AppErrorType.network", "AppErrorType.dataLoading", "AppErrorType.authentication",
            "AppErrorType.permission", "AppErrorType.validation", "AppErrorType.payment",
            "AppErrorType.ai", "AppErrorType.api", "AppErrorType.storage", "AppErrorType.sync", 
            "AppErrorType.unknown"
        ], width=20)
        self.type_filter.grid(row=0, column=1, padx=(0, 10), sticky=tk.W)
        self.type_filter.bind('<<ComboboxSelected>>', lambda e: self.load_errors())
        
        ttk.Label(filter_frame, text="User ID:").grid(row=0, column=2, padx=(0, 5), sticky=tk.W)
        self.user_filter = ttk.Entry(filter_frame, width=20)
        self.user_filter.grid(row=0, column=3, padx=(0, 10), sticky=tk.W)
        self.user_filter.bind('<KeyRelease>', lambda e: self.load_errors())
        
        ttk.Label(filter_frame, text="Question ID:").grid(row=0, column=4, padx=(0, 5), sticky=tk.W)
        self.question_filter = ttk.Entry(filter_frame, width=15)
        self.question_filter.grid(row=0, column=5, padx=(0, 10), sticky=tk.W)
        self.question_filter.bind('<KeyRelease>', lambda e: self.load_errors())
        
        # Error list
        list_frame = ttk.LabelFrame(main_frame, text="Errors", padding="5")
        list_frame.grid(row=3, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 5))
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        
        # Treeview for error list
        columns = ('timestamp', 'type', 'user_id', 'question_id', 'error_msg')
        self.error_tree = ttk.Treeview(list_frame, columns=columns, show='headings', height=15)
        
        # Define headings
        self.error_tree.heading('timestamp', text='Timestamp', command=lambda: self.sort_column('timestamp', False))
        self.error_tree.heading('type', text='Type', command=lambda: self.sort_column('type', False))
        self.error_tree.heading('user_id', text='User ID', command=lambda: self.sort_column('user_id', False))
        self.error_tree.heading('question_id', text='Question ID', command=lambda: self.sort_column('question_id', False))
        self.error_tree.heading('error_msg', text='Error Message', command=lambda: self.sort_column('error_msg', False))
        
        # Define column widths
        self.error_tree.column('timestamp', width=150)
        self.error_tree.column('type', width=120)
        self.error_tree.column('user_id', width=100)
        self.error_tree.column('question_id', width=80)
        self.error_tree.column('error_msg', width=300)
        
        # Add scrollbar
        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.error_tree.yview)
        self.error_tree.configure(yscrollcommand=scrollbar.set)
        
        self.error_tree.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        
        # Bind selection event
        self.error_tree.bind('<<TreeviewSelect>>', self.on_error_select)
        
        # Details panel
        details_frame = ttk.LabelFrame(main_frame, text="Error Details", padding="5")
        details_frame.grid(row=3, column=1, sticky=(tk.W, tk.E, tk.N, tk.S))
        details_frame.columnconfigure(0, weight=1)
        details_frame.rowconfigure(0, weight=1)
        
        # Create text widget with scrollbar for details
        self.details_text = scrolledtext.ScrolledText(details_frame, wrap=tk.WORD, width=50, height=30)
        self.details_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Status bar
        self.status_var = tk.StringVar()
        self.status_var.set("Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W)
        status_bar.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))
    
    def sort_column(self, col, reverse):
        """Sort treeview contents when a column header is clicked"""
        # Get all children
        children = self.error_tree.get_children('')
        
        # Prepare list of tuples (value, item) for sorting
        sort_list = []
        for child in children:
            value = self.error_tree.set(child, col)
            sort_list.append((value, child))
        
        # Sort the list
        sort_list.sort(reverse=reverse)
        
        # Rearrange items in sorted order
        for index, (val, item) in enumerate(sort_list):
            self.error_tree.move(item, '', index)
        
        # Reverse sort order for next click
        self.error_tree.heading(col, command=lambda: self.sort_column(col, not reverse))
    
    def load_errors(self, event=None):
        """Load errors from Supabase with optional filtering"""
        if not self.supabase_client:
            messagebox.showerror("Error", "Not connected to Supabase. Please check your credentials.")
            return
        
        try:
            # Build query with filters
            query = self.supabase_client.table('error_reports').select('*').order('timestamp', desc=True)
            
            # Apply filters
            error_type = self.type_filter.get()
            if error_type:
                query = query.eq('error_type', error_type)
            
            user_id = self.user_filter.get().strip()
            if user_id:
                query = query.eq('user_id', user_id)
            
            question_id = self.question_filter.get().strip()
            if question_id:
                query = query.eq('question_id', question_id)
            
            # Execute query
            response = query.execute()
            
            # Clear existing items
            for item in self.error_tree.get_children():
                self.error_tree.delete(item)
            
            # Add new items
            for error in response.data:
                timestamp = error.get('timestamp', '')[:19]  # Get only the datetime part
                error_type = error.get('error_type', '')
                user_id = error.get('user_id', '')
                question_id = error.get('question_id', '')
                error_msg = error.get('user_message', '') or error.get('error_message', '')
                
                # Truncate error message if too long
                if len(error_msg) > 50:
                    error_msg = error_msg[:50] + "..."
                
                self.error_tree.insert('', tk.END, values=(
                    timestamp,
                    error_type,
                    user_id,
                    question_id,
                    error_msg
                ), tags=(error['id'],))  # Store error ID as tag
            
            self.status_var.set(f"Loaded {len(response.data)} errors")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load errors: {str(e)}")
            self.status_var.set("Error loading errors")
    
    def on_error_select(self, event):
        """Handle error selection in the treeview"""
        selection = self.error_tree.selection()
        if not selection:
            return
        
        item = self.error_tree.item(selection[0])
        error_id = item['tags'][0]  # Get error ID from tags
        
        self.show_error_details(error_id)
    
    def show_error_details(self, error_id):
        """Show detailed information for a selected error"""
        if not self.supabase_client:
            return
        
        try:
            response = self.supabase_client.table('error_reports').select('*').eq('id', error_id).execute()
            if not response.data:
                self.details_text.delete(1.0, tk.END)
                self.details_text.insert(tk.END, "Error not found")
                return
            
            error = response.data[0]
            
            # Clear text widget
            self.details_text.delete(1.0, tk.END)
            
            # Format and display error details
            details = f"""ERROR DETAILS

ID: {error.get('id', '')}
Timestamp: {error.get('timestamp', '')}
Error Type: {error.get('error_type', '')}
User ID: {error.get('user_id', 'N/A')}
Question ID: {error.get('question_id', 'N/A')}

ERROR INFORMATION
Technical Message: {error.get('error_message', '')}
User Message: {error.get('user_message', '')}
Error Code: {error.get('error_code', 'N/A')}

CONTEXT INFORMATION
Context: {error.get('context', 'N/A')}
Additional Info: {error.get('additional_info', 'N/A')}
Stack Trace: {error.get('stack_trace', 'N/A')}

APP INFORMATION
Device Info: {error.get('device_info', 'N/A')}
App Version: {error.get('app_version', 'N/A')}
Build Number: {error.get('build_number', 'N/A')}

"""
            
            self.details_text.insert(tk.END, details)
            
        except Exception as e:
            self.details_text.delete(1.0, tk.END)
            self.details_text.insert(tk.END, f"Error loading details: {str(e)}")
    
    def clear_filters(self):
        """Clear all filters and reload all errors"""
        self.type_filter.set('')
        self.user_filter.delete(0, tk.END)
        self.question_filter.delete(0, tk.END)
        self.load_errors()

def main():
    root = tk.Tk()
    app = ErrorReportingAdminGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()