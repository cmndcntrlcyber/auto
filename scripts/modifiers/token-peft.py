import os
from nltk import word_tokenize
from docx import Document
import pandas as pd

def tokenize_text(text):
    # Tokenizes the text and returns a list of tokens.
    return word_tokenize(text)

def process_file(path, extension):
    if extension == '.docx':
        doc = Document(path)
        fullText = []
        for para in doc.paragraphs:
            fullText.append(para.text)
        return tokenize_text('\n'.join(fullText))
    elif extension == '.txt':
        with open(path, 'r') as file:
            text = file.read()
        return tokenize_text(text)
    elif extension == '.csv':
        df = pd.read_csv(path)
        fullText = '\n'.join([str(x) for x in df.values])
        return tokenize_text(fullText)
    else:
        print('Unsupported file type: ' + path)

def main():
    directory = './your-directory'  # replace with your directory
    
    for filename in os.listdir(directory):
        if filename.endswith('.docx') or filename.endswith('.txt') or filename.endswith('.csv'):
            path = os.path.join(directory, filename)
            tokens = process_file(path, extension=os.path.splitext(filename)[1])
            print('Tokens for {}: {}'.format(filename, tokens))
            
if __name__ == "__main__":
    main()