@app.get("/")
def root():
    return {"message": "Welkom bij de Bijbel-API! Zie /docs voor documentatie."}