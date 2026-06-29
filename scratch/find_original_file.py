import os
import json

log_dir = r"C:\Users\ASUS\.gemini\antigravity\brain\5a69f0f0-0eee-4ec8-8d0a-8f3cdb429496\.system_generated\logs"
transcript_path = os.path.join(log_dir, "transcript_full.jsonl")

if not os.path.exists(transcript_path):
    print("Transcript not found at:", transcript_path)
    # Check if there is transcript.jsonl
    transcript_path = os.path.join(log_dir, "transcript.jsonl")

print("Reading transcript from:", transcript_path)
found = False
with open(transcript_path, "r", encoding="utf-8") as f:
    for line in f:
        try:
            data = json.loads(line)
            # Search for tools that read or write FieldCreator.gd
            if "tool_calls" in data:
                for call in data["tool_calls"]:
                    if "AbsolutePath" in call.get("arguments", {}):
                        path = call["arguments"]["AbsolutePath"]
                        if "FieldCreator.gd" in path:
                            print("Found read_file call in step", data.get("step_index"))
                            found = True
                    if "TargetFile" in call.get("arguments", {}):
                        path = call["arguments"]["TargetFile"]
                        if "FieldCreator.gd" in path:
                            print("Found write_file/replace call in step", data.get("step_index"))
                            found = True
        except Exception as e:
            pass

if not found:
    print("No FieldCreator.gd reference found in transcript.")
