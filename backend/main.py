from fastapi import FastAPI

app = FastAPI(title="ZTL Rome API")

@app.get("/api/health")
def health():
    return {"status": "ok"}
