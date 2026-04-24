"""Demo FastAPI app — replace with real code."""
from fastapi import FastAPI

app = FastAPI(title="demo-api")


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}
