from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware  # 🔥 ADD THIS
import shutil
import os
from inference import run_model

app = FastAPI()

# 🔥 ADD THIS BLOCK (VERY IMPORTANT)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all (for now)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# create temp folder
os.makedirs("temp", exist_ok=True)

@app.post("/analyze")
async def analyze(file: UploadFile = File(...)):
    
    # Use os.path.join for cross-platform compatibility (works on Windows & Linux)
    file_path = os.path.join("temp", file.filename)
    
    try:
        # save file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # run model
        result = run_model(file_path)
        
        return result
    
    finally:
        # Clean up temp file after processing
        if os.path.exists(file_path):
            os.remove(file_path)