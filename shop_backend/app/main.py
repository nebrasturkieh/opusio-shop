from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello Nebras! Your backend is running 🚀"}
