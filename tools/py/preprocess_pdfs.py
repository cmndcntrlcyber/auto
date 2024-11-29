import os
import fitz  # PyMuPDF
import sys

def extract_text_from_pdf(pdf_path):
    """
    Extracts text from a single PDF file.
    """
    try:
        document = fitz.open(pdf_path)
        text = ""
        for page_num in range(len(document)):
            page = document[page_num]
            text += page.get_text()  # Extract text from each page
        document.close()
        return text
    except Exception as e:
        print(f"Error processing {pdf_path}: {e}")
        return ""

def preprocess_pdfs(input_dir, output_dir):
    """
    Processes all PDF files in a directory, extracting their text and saving it as .txt files.
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for file_name in os.listdir(input_dir):
        if file_name.lower().endswith('.pdf'):
            input_path = os.path.join(input_dir, file_name)
            output_path = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}.txt")
            
            print(f"Processing: {file_name}")
            extracted_text = extract_text_from_pdf(input_path)
            
            with open(output_path, "w", encoding="utf-8") as text_file:
                text_file.write(extracted_text)
                print(f"Saved extracted text to: {output_path}")

if __name__ == "__main__":
    # Ensure proper argument handling
    if len(sys.argv) != 3:
        print("Usage: python preprocess_pdfs.py <input_directory> <output_directory>")
        sys.exit(1)

    # Define input and output directories from command-line arguments
    input_directory = sys.argv[1]
    output_directory = sys.argv[2]

    preprocess_pdfs(input_directory, output_directory)
