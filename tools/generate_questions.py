import google.generativeai as genai
import os
import json
import argparse
import time

def setup_gemini():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set.")
        print("Get your free API key from https://aistudio.google.com/app/apikey")
        print("Then run: export GEMINI_API_KEY=AIzaSyCxwdOA3U8D_i7qxyx1hDIlXgjo0BcLJLM")
        exit(1)
    genai.configure(api_key=api_key)

def upload_to_gemini(path, mime_type=None):
    """Uploads the given file to Gemini."""
    print(f"Uploading {path} to Gemini API...")
    file = genai.upload_file(path, mime_type=mime_type)
    print(f"Uploaded file '{file.display_name}' as: {file.uri}")
    return file

def wait_for_files_active(files):
    """Waits for the given files to be active."""
    print("Waiting for file processing...")
    for name in (file.name for file in files):
        file = genai.get_file(name)
        while file.state.name == "PROCESSING":
            print(".", end="", flush=True)
            time.sleep(5)
            file = genai.get_file(name)
        if file.state.name != "ACTIVE":
            raise Exception(f"File {file.name} failed to process")
    print("...all files ready")

def generate_questions(pdf_path, subject, chapter, num_questions=20):
    setup_gemini()
    
    # Upload the PDF
    pdf_file = upload_to_gemini(pdf_path, mime_type="application/pdf")
    wait_for_files_active([pdf_file])
    
    # Configure the model
    # Using gemini-1.5-pro for complex PDF parsing and high-quality question generation
    model = genai.GenerativeModel(
        model_name="gemini-1.5-pro",
        generation_config={
            "temperature": 0.4,
            "response_mime_type": "application/json",
        }
    )
    
    prompt = f"""
    You are an expert NEET (medical entrance exam) tutor.
    I have attached a chapter from an NCERT textbook for {subject}, chapter {chapter}.
    Please read the attached PDF and generate {num_questions} high-quality, NEET-level Multiple Choice Questions (MCQs) based strictly on the content of this chapter.
    
    The questions should range in difficulty (Easy, Medium, Hard).
    
    Respond ONLY with a JSON array of objects, where each object represents a question with the following schema:
    [
      {{
        "subject": "{subject}",
        "chapter": "{chapter}",
        "topic": "Specific topic within the chapter",
        "questionText": "The actual question text",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correctAnswer": "The exact text of the correct option",
        "explanation": "A detailed explanation of why the answer is correct.",
        "difficulty": "Easy/Medium/Hard"
      }}
    ]
    """
    
    print(f"Generating {num_questions} questions... (this may take a minute)")
    response = model.generate_content([pdf_file, prompt])
    
    try:
        # Parse the JSON response
        questions = json.loads(response.text)
        
        # Save to file
        output_file = f"{subject}_{chapter}_questions.json".replace(" ", "_").lower()
        with open(output_file, 'w') as f:
            json.dump(questions, f, indent=2)
        
        print(f"Successfully generated {len(questions)} questions!")
        print(f"Saved to: {output_file}")
        
    except json.JSONDecodeError:
        print("Failed to parse JSON response from Gemini. Raw response:")
        print(response.text)
        
    # Cleanup
    print("Cleaning up file from Gemini servers...")
    genai.delete_file(pdf_file.name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate NEET questions from NCERT PDFs using Gemini API")
    parser.add_argument("pdf_path", help="Path to the NCERT PDF file")
    parser.add_argument("--subject", required=True, help="Subject (e.g. Biology)")
    parser.add_argument("--chapter", required=True, help="Chapter Name (e.g. The Living World)")
    parser.add_argument("--num", type=int, default=20, help="Number of questions to generate")
    
    args = parser.parse_args()
    generate_questions(args.pdf_path, args.subject, args.chapter, args.num)
    
    print("\nNext step: Copy the output JSON into your flutter app and map it to your Drift database!")
