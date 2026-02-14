package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

type Tab struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type KeyValue struct {
	ID    int    `json:"id"`
	TabID int    `json:"tab_id"`
	Key   string `json:"key"`
	Value string `json:"value"`
}

var db *sql.DB
var logFile *os.File
var authTokens map[string]struct{}

func initDB() error {
	var err error
	db, err = sql.Open("sqlite3", "./data/app.db")
	if err != nil {
		return err
	}

	createTabsTable := `
	CREATE TABLE IF NOT EXISTS tabs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL
	);`

	createKVTable := `
	CREATE TABLE IF NOT EXISTS key_values (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		tab_id INTEGER NOT NULL,
		key TEXT NOT NULL,
		value TEXT NOT NULL,
		FOREIGN KEY(tab_id) REFERENCES tabs(id) ON DELETE CASCADE
	);`

	_, err = db.Exec(createTabsTable)
	if err != nil {
		return err
	}

	_, err = db.Exec(createKVTable)
	return err
}

func initLogger() error {
	os.MkdirAll("./logs", 0755)
	var err error
	logFile, err = os.OpenFile("./logs/app.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	log.SetOutput(logFile)
	log.SetFlags(0)
	return nil
}

func main() {
	os.MkdirAll("./data", 0755)
	authTokens = parseTokens(loadTokens())

	if err := initDB(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	if err := initLogger(); err != nil {
		log.Fatal("Failed to initialize logger:", err)
	}
	defer logFile.Close()

	http.HandleFunc("/", serveHome)
	http.HandleFunc("/api/login", handleLogin)
	http.HandleFunc("/api/tabs", requireAuth(handleTabs))
	http.HandleFunc("/api/tabs/delete", requireAuth(deleteTab))
	http.HandleFunc("/api/tabs/rename", requireAuth(renameTab))
	http.HandleFunc("/api/keyvalues", requireAuth(handleKeyValues))
	http.HandleFunc("/api/submit", requireAuth(handleSubmit))

	fmt.Println("Server starting on :8907...")
	log.Fatal(http.ListenAndServe(":8907", nil))
}

func serveHome(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "static/index.html")
}

func requireAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !isAuthorized(r) {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

func isAuthorized(r *http.Request) bool {
	if len(authTokens) == 0 {
		return true
	}

	if c, err := r.Cookie("kj_token"); err == nil && tokenAllowed(c.Value) {
		return true
	}

	if token := r.Header.Get("X-Auth-Token"); tokenAllowed(token) {
		return true
	}

	if authHeader := r.Header.Get("Authorization"); strings.HasPrefix(authHeader, "Bearer ") {
		if tokenAllowed(strings.TrimPrefix(authHeader, "Bearer ")) {
			return true
		}
	}

	if token := r.URL.Query().Get("token"); tokenAllowed(token) {
		return true
	}

	return false
}

func tokenAllowed(token string) bool {
	if token == "" {
		return false
	}
	_, ok := authTokens[token]
	return ok
}

func parseTokens(raw string) map[string]struct{} {
	tokens := make(map[string]struct{})
	for _, t := range strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == '\n' || r == '\r' || r == '\t' || r == ' '
	}) {
		t = strings.TrimSpace(t)
		if t != "" {
			tokens[t] = struct{}{}
		}
	}
	return tokens
}

func loadTokens() string {
	if path := strings.TrimSpace(os.Getenv("KEYJOURNAL_TOKENS_FILE")); path != "" {
		if data, err := os.ReadFile(path); err == nil {
			return strings.TrimSpace(string(data))
		}
	}
	return os.Getenv("KEYJOURNAL_TOKENS")
}

func handleLogin(w http.ResponseWriter, r *http.Request) {
	if len(authTokens) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if !tokenAllowed(data.Token) {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	cookie := &http.Cookie{
		Name:     "kj_token",
		Value:    data.Token,
		Path:     "/",
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
	}
	if r.TLS != nil {
		cookie.Secure = true
	}
	http.SetCookie(w, cookie)
	w.WriteHeader(http.StatusOK)
}

func handleTabs(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		rows, err := db.Query("SELECT id, name FROM tabs")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var tabs []Tab
		for rows.Next() {
			var tab Tab
			if err := rows.Scan(&tab.ID, &tab.Name); err != nil {
				continue
			}
			tabs = append(tabs, tab)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(tabs)

	case "POST":
		var tab Tab
		if err := json.NewDecoder(r.Body).Decode(&tab); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		result, err := db.Exec("INSERT INTO tabs (name) VALUES (?)", tab.Name)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		id, _ := result.LastInsertId()
		tab.ID = int(id)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(tab)
	}
}

func deleteTab(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data struct {
		ID int `json:"id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.Exec("DELETE FROM key_values WHERE tab_id = ?", data.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = db.Exec("DELETE FROM tabs WHERE id = ?", data.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func renameTab(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data struct {
		ID   int    `json:"id"`
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.Exec("UPDATE tabs SET name = ? WHERE id = ?", data.Name, data.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func handleKeyValues(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		tabID := r.URL.Query().Get("tab_id")
		if tabID == "" {
			http.Error(w, "tab_id required", http.StatusBadRequest)
			return
		}

		rows, err := db.Query("SELECT id, tab_id, key, value FROM key_values WHERE tab_id = ?", tabID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var kvs []KeyValue
		for rows.Next() {
			var kv KeyValue
			if err := rows.Scan(&kv.ID, &kv.TabID, &kv.Key, &kv.Value); err != nil {
				continue
			}
			kvs = append(kvs, kv)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(kvs)

	case "POST":
		var data struct {
			TabID     int               `json:"tab_id"`
			KeyValues map[string]string `json:"key_values"`
		}
		if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Delete existing key-values for this tab
		_, err := db.Exec("DELETE FROM key_values WHERE tab_id = ?", data.TabID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Insert new key-values
		for key, value := range data.KeyValues {
			_, err := db.Exec("INSERT INTO key_values (tab_id, key, value) VALUES (?, ?, ?)",
				data.TabID, key, value)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
		}

		w.WriteHeader(http.StatusOK)
	}
}

func handleSubmit(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data struct {
		TabName   string            `json:"tab_name"`
		KeyValues map[string]string `json:"key_values"`
	}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Build JSON with timestamp first
	logEntry := fmt.Sprintf(`{"timestamp":"%s"`, time.Now().Format(time.RFC3339))
	
	// Add all key-value pairs
	for key, value := range data.KeyValues {
		keyJSON, _ := json.Marshal(key)
		valueJSON, _ := json.Marshal(value)
		logEntry += fmt.Sprintf(`,%s:%s`, keyJSON, valueJSON)
	}
	
	// Add tab_name last
	tabNameJSON, _ := json.Marshal(data.TabName)
	logEntry += fmt.Sprintf(`,"tab_name":%s}`, tabNameJSON)

	log.Println(logEntry)

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Logged successfully"))
}
