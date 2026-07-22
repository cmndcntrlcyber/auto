#!/usr/bin/env python3
"""
pdf_rag_preparer.py

Prepare a directory of PDFs for Retrieval‑Augmented Generation:
  • Text extraction (Tika or PyPDF2)
  • Chunking with overlap
  • Embedding via OpenAI/Ollama
  • Storage in Chromadb

Usage:
  pip install tika langchain openai chromadb
  export OPENAI_API_KEY=your_key_here
  python pdf_rag_preparer.py \
    --pdf-dir ./pdfs \
    --tika-url http://localhost:9998 \
    --output-dir ./vector_db \
    --chunk-size 1000 \
    --chunk-overlap 200
"""

import os
import argparse
from pathlib import Path
from typing import List

# Optional: for Apache Tika extraction
from tika import parser as tika_parser

# LangChain components
from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma


def extract_text_tika(path: Path, server_url: str) -> str:
    parsed = tika_parser.from_file(str(path), server_url=server_url)
    return parsed.get("content", "") or ""


def extract_text_pdf(path: Path) -> str:
    # Fallback pure-Python extraction
    from PyPDF2 import PdfReader
    reader = PdfReader(str(path))
    return "\n\n".join(p.extract_text() or "" for p in reader.pages)


def load_documents(
    pdf_dir: Path, use_tika: bool, tika_url: str
) -> List[Document]:
    docs = []
    for file in pdf_dir.glob("*.pdf"):
        raw = (extract_text_tika(file, tika_url) if use_tika
               else extract_text_pdf(file))
        if not raw.strip():
            continue
        docs.append(Document(page_content=raw, metadata={"source": str(file)}))
    return docs


def chunk_documents(
    docs: List[Document],
    chunk_size: int,
    chunk_overlap: int
) -> List[Document]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len
    )
    return splitter.split_documents(docs)


def embed_and_store(
    docs: List[Document],
    persist_dir: Path,
    embedding_model: str
):
    embedder = OpenAIEmbeddings(model=embedding_model)
    db = Chroma(persist_directory=str(persist_dir),
                embedding_function=embedder)
    db.add_documents(docs)
    db.persist()


def main():
    p = argparse.ArgumentParser(
        description="Prepare PDFs for text embedding & RAG"
    )
    p.add_argument("--pdf-dir", type=Path, required=True,
                   help="Directory containing .pdf files")
    p.add_argument("--output-dir", type=Path, required=True,
                   help="Where to persist the vector DB")
    p.add_argument("--tika-url", default="http://localhost:9998",
                   help="Tika server URL (if using Tika)")
    p.add_argument("--no-tika", action="store_true",
                   help="Disable Apache Tika and use PyPDF2")
    p.add_argument("--chunk-size", type=int, default=1000,
                   help="Characters per chunk")
    p.add_argument("--chunk-overlap", type=int, default=200,
                   help="Overlap between chunks")
    p.add_argument("--model", default="text-embedding-ada-002",
                   help="Embedding model name")
    args = p.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    raw_docs = load_documents(
        args.pdf_dir,
        use_tika=not args.no_tika,
        tika_url=args.tika_url
    )
    if not raw_docs:
        print("No text extracted from any PDF in", args.pdf_dir)
        return

    chunks = chunk_documents(raw_docs, args.chunk_size, args.chunk_overlap)
    print(f"Split into {len(chunks)} chunks; embedding with {args.model}…")

    embed_and_store(chunks, args.output_dir, args.model)
    print("✅ Done. Vectors persisted in", args.output_dir)


if __name__ == "__main__":
    main()
