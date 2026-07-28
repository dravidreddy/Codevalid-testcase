from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Dict
import os

app = FastAPI(title="Testing Codevalid Chatbot")

class ChatMessage(BaseModel):
    sender: str  # "user" or "bot"
    text: str

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str
    sender: str = "bot"

# In-memory session chat history
chat_history: List[Dict[str, str]] = []

def generate_bot_response(user_text: str) -> str:
    cleaned = user_text.strip().lower()
    if cleaned in ["hi", "hello", "hey", "hullo"]:
        return "Hello! How can I help you today?"
    elif "help" in cleaned:
        return "I can assist you with testing Codevalid. Feel free to send a message!"
    elif "who are you" in cleaned or "what are you" in cleaned:
        return "I am a simple testing chatbot built for Codevalid feature verification."
    elif "bye" in cleaned or "goodbye" in cleaned:
        return "Goodbye! Have a great day."
    else:
        return f"Echo response: '{user_text}'. I am here to help you test Codevalid!"

@app.get("/", response_class=HTMLResponse)
async def get_index():
    with open("index.html", "r", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())

@app.post("/api/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")
    
    user_msg = request.message.strip()
    reply_msg = generate_bot_response(user_msg)
    
    chat_history.append({"sender": "user", "text": user_msg})
    chat_history.append({"sender": "bot", "text": reply_msg})
    
    return ChatResponse(reply=reply_msg)

@app.get("/api/history")
async def get_history():
    return {"history": chat_history}

@app.post("/api/clear")
async def clear_history():
    chat_history.clear()
    return {"status": "cleared"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
