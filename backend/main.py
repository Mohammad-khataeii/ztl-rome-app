from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from ztl_service import (
    centro_notturna_area as get_centro_notturna_area,
    centro_notturna_gates as get_centro_notturna_gates,
    centro_notturna_summary as get_centro_notturna_summary,
)

app = FastAPI(title="ZTL Rome API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/ztl/centro-notturna")
def centro_notturna_summary():
    return get_centro_notturna_summary()


@app.get("/api/ztl/centro-notturna/area")
def centro_notturna_area():
    return get_centro_notturna_area()


@app.get("/api/ztl/centro-notturna/gates")
def centro_notturna_gates():
    return get_centro_notturna_gates()
