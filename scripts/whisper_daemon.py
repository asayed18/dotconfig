import os
import sys
import socket
import threading
from faster_whisper import WhisperModel

# Configuration
MODEL_NAME = "medium.en" # Heavy-duty model for high accuracy
SOCKET_PATH = "/tmp/whisper_ptt.socket"
# Context for better technical accuracy
INITIAL_PROMPT = "Linux terminal command bash sudo apt install bspwm sxhkd polybar python script java javascript variable semicolon git commit branch code snippet"

print(f"Loading Whisper model '{MODEL_NAME}' into GPU (CUDA)...")
model = WhisperModel(MODEL_NAME, device="cuda", compute_type="int8_float16")
print("Model loaded into GPU and ready.")

def handle_client(conn):
    try:
        # Receive the path to the audio file
        audio_file = conn.recv(1024).decode('utf-8').strip()
        print(f"Received request for audio file: {audio_file}")
        if not audio_file or not os.path.exists(audio_file):
            print(f"ERROR: File not found: {audio_file}")
            conn.sendall(b"ERROR: Invalid file")
            return

        # Inference
        print(f"Starting transcription for {audio_file}...")
        segments, _ = model.transcribe(
            audio_file,
            language="en",
            vad_filter=True,
            beam_size=1,
            initial_prompt=INITIAL_PROMPT
        )
        text = " ".join(s.text.strip() for s in segments).strip()
        print(f"Transcription complete. Result: '{text}'")
        
        # Post-processing for spoken formatting commands
        replacements = {
            " new line": "\n", " newline": "\n", " return": "\n", " enter": "\n",
            " semi-colon": ";", " semicolon": ";",
            " equals": " =", " equal": " =",
            " underscore ": "_", " underscore": "_", "underscore ": "_",
            " dot": ".", " point": ".", " period": ".",
            " open press": "(", " close press": ")",
            " open bracket": "(", " close bracket": ")",
            " open brace": "{", " close brace": "}",
            " open paren": "(", " close paren": ")",
            " plus": " +", " minus": " -",
        }
        for spoken, symbol in replacements.items():
            text = text.replace(spoken, symbol)

        # Send back the result
        print(f"Sending result back to client...")
        conn.sendall(text.encode('utf-8'))
    except Exception as e:
        print(f"ERROR during handling client: {e}")
        import traceback
        traceback.print_exc()
    finally:
        conn.close()

if os.path.exists(SOCKET_PATH):
    os.remove(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
os.chmod(SOCKET_PATH, 0o666)
server.listen(5)

print(f"Listening on {SOCKET_PATH}...")
try:
    while True:
        conn, _ = server.accept()
        threading.Thread(target=handle_client, args=(conn,)).start()
except KeyboardInterrupt:
    pass
finally:
    server.close()
    os.remove(SOCKET_PATH)
