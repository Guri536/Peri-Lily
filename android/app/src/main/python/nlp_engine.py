import json
import difflib

def analyze_for_triggers(transcribed_text, safe_words_json):
    if not transcribed_text:
        return False

    try:
        safe_words = json.loads(safe_words_json)
    except json.JSONDecodeError:
        return False

    transcribed_text = transcribed_text.lower()

    for word in safe_words:
        target = word.lower()

        if target in transcribed_text:
            return True

        words_in_text = transcribed_text.split()
        for spoken_word in words_in_text:
            similarity = difflib.SequenceMatcher(None, target, spoken_word).ratio()
            if similarity > 0.85:  # 85% confidence threshold
                return True

    return False