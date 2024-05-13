import os
from pathlib import Path
from python_docx import Document
import pandas as pd

# Directory containing files to be processed
dir_path = "/path/to/your/directory"

for filename in os.listdir(dir_path):
    file_path = os.path.join(dir_path, filename)
    
    # Determine the output file based on file type
    if Path(filename).suffix == '.docx':
        output_file = "processed_" + filename.replace('.docx', '.txt')  # Replace .docx with .txt for txt files
    elif Path(filename).suffix in ['.csv', '.txt']:
        output_file = "processed_" + filename  
        
    with open(output_file, 'w') as out:
        if Path(filename).suffix == '.docx':
            doc = Document(file_path)
            for paragraph in doc.paragraphs:
                out.write(paragraph.text + '\n')
                
        elif Path(filename).suffix == '.txt':
            with open(file_path, 'r') as f:
                lines = f.readlines()
                for line in lines:
                    out.write(line)  # Don't add a new line here, txt files already have them
                    
        elif Path(filename).suffix == '.csv':
            df = pd.read_csv(file_path)
            for col in df.columns:
                for item in df[col]:
                    if isinstance(item, str):
                        out.write(item + '\n')  # Add a new line here to match txt files