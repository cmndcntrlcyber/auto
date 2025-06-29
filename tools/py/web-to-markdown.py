"""
Web to Markdown Converter

A tool for extracting code blocks and images from web pages and converting
them to Markdown format. Useful for documentation, research, and content
extraction from web sources.

Features:
- Extract code blocks from web pages
- Extract and reference images
- Clean HTML parsing with BeautifulSoup
- Error handling and validation
- Command-line interface

Author: Security Automation Team
Version: 2.0.0
License: MIT
"""

import requests
from bs4 import BeautifulSoup
import sys
import argparse
import logging
from urllib.parse import urljoin, urlparse
from pathlib import Path
import time
from typing import List, Dict, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class WebToMarkdownConverter:
    """
    Web to Markdown converter with enhanced features
    """
    
    def __init__(self, timeout: int = 30, user_agent: Optional[str] = None):
        """
        Initialize the converter
        
        Args:
            timeout (int): Request timeout in seconds
            user_agent (str, optional): Custom user agent string
        """
        self.timeout = timeout
        self.session = requests.Session()
        
        # Set user agent
        if user_agent:
            self.session.headers.update({'User-Agent': user_agent})
        else:
            self.session.headers.update({
                'User-Agent': 'WebToMarkdownConverter/2.0.0 (Security Research Tool)'
            })
    
    def fetch_webpage(self, url: str) -> Optional[BeautifulSoup]:
        """
        Fetch and parse a webpage
        
        Args:
            url (str): URL to fetch
            
        Returns:
            BeautifulSoup: Parsed HTML content or None if failed
        """
        try:
            logger.info(f"Fetching webpage: {url}")
            response = self.session.get(url, timeout=self.timeout)
            response.raise_for_status()
            
            # Parse with BeautifulSoup
            soup = BeautifulSoup(response.content, 'html.parser')
            logger.info(f"Successfully parsed webpage: {url}")
            return soup
            
        except requests.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None
        except Exception as e:
            logger.error(f"Error parsing {url}: {e}")
            return None
    
    def extract_code_blocks(self, soup: BeautifulSoup) -> List[Dict[str, str]]:
        """
        Extract code blocks from parsed HTML
        
        Args:
            soup (BeautifulSoup): Parsed HTML content
            
        Returns:
            List[Dict]: List of code blocks with metadata
        """
        code_blocks = []
        
        # Find all code tags
        code_tags = soup.find_all(['code', 'pre'])
        
        for i, tag in enumerate(code_tags):
            code_text = tag.get_text().strip()
            if code_text:  # Only include non-empty code blocks
                
                # Try to determine language from class attributes
                language = 'text'  # default
                if tag.get('class'):
                    classes = ' '.join(tag.get('class'))
                    # Common patterns for language detection
                    if 'python' in classes.lower():
                        language = 'python'
                    elif 'javascript' in classes.lower() or 'js' in classes.lower():
                        language = 'javascript'
                    elif 'bash' in classes.lower() or 'shell' in classes.lower():
                        language = 'bash'
                    elif 'sql' in classes.lower():
                        language = 'sql'
                    elif 'json' in classes.lower():
                        language = 'json'
                    elif 'xml' in classes.lower() or 'html' in classes.lower():
                        language = 'xml'
                
                code_blocks.append({
                    'index': i + 1,
                    'language': language,
                    'content': code_text,
                    'tag_name': tag.name
                })
        
        logger.info(f"Extracted {len(code_blocks)} code blocks")
        return code_blocks
    
    def extract_images(self, soup: BeautifulSoup, base_url: str) -> List[Dict[str, str]]:
        """
        Extract images from parsed HTML
        
        Args:
            soup (BeautifulSoup): Parsed HTML content
            base_url (str): Base URL for resolving relative URLs
            
        Returns:
            List[Dict]: List of images with metadata
        """
        images = []
        img_tags = soup.find_all('img')
        
        for i, tag in enumerate(img_tags):
            src = tag.get('src')
            if src:
                # Resolve relative URLs
                full_url = urljoin(base_url, src)
                
                # Get alt text and title
                alt_text = tag.get('alt', f'Image {i + 1}')
                title = tag.get('title', '')
                
                images.append({
                    'index': i + 1,
                    'src': full_url,
                    'alt': alt_text,
                    'title': title
                })
        
        logger.info(f"Extracted {len(images)} images")
        return images
    
    def generate_markdown(self, code_blocks: List[Dict], images: List[Dict], 
                         url: str, include_metadata: bool = True) -> str:
        """
        Generate Markdown content from extracted data
        
        Args:
            code_blocks (List[Dict]): Extracted code blocks
            images (List[Dict]): Extracted images
            url (str): Source URL
            include_metadata (bool): Whether to include metadata
            
        Returns:
            str: Generated Markdown content
        """
        markdown_content = []
        
        # Add header with metadata
        if include_metadata:
            markdown_content.extend([
                f"# Web Content Extraction",
                f"",
                f"**Source URL:** {url}",
                f"**Extracted on:** {time.strftime('%Y-%m-%d %H:%M:%S')}",
                f"**Code blocks found:** {len(code_blocks)}",
                f"**Images found:** {len(images)}",
                f"",
                "---",
                f""
            ])
        
        # Add code blocks section
        if code_blocks:
            markdown_content.extend([
                "## Code Blocks",
                ""
            ])
            
            for block in code_blocks:
                markdown_content.extend([
                    f"### Code Block {block['index']} ({block['language']})",
                    "",
                    f"```{block['language']}",
                    block['content'],
                    "```",
                    ""
                ])
        
        # Add images section
        if images:
            markdown_content.extend([
                "## Images",
                ""
            ])
            
            for img in images:
                title_text = f" \"{img['title']}\"" if img['title'] else ""
                markdown_content.extend([
                    f"### Image {img['index']}",
                    "",
                    f"![{img['alt']}]({img['src']}{title_text})",
                    ""
                ])
        
        # Add footer
        if include_metadata:
            markdown_content.extend([
                "---",
                "",
                "*Generated by WebToMarkdownConverter*"
            ])
        
        return "\n".join(markdown_content)
    
    def convert_url_to_markdown(self, url: str, output_file: str, 
                               include_metadata: bool = True) -> bool:
        """
        Convert a web page to Markdown format
        
        Args:
            url (str): URL to convert
            output_file (str): Output file path
            include_metadata (bool): Whether to include metadata
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Fetch and parse webpage
            soup = self.fetch_webpage(url)
            if not soup:
                return False
            
            # Extract content
            code_blocks = self.extract_code_blocks(soup)
            images = self.extract_images(soup, url)
            
            # Generate Markdown
            markdown_content = self.generate_markdown(
                code_blocks, images, url, include_metadata
            )
            
            # Write to file
            output_path = Path(output_file)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown_content)
            
            logger.info(f"Markdown content saved to: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"Error converting {url} to Markdown: {e}")
            return False


def main():
    """
    Main function with command-line interface
    """
    parser = argparse.ArgumentParser(
        description="Convert web pages to Markdown format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic conversion
  python web-to-markdown.py https://example.com/docs output.md

  # With custom user agent
  python web-to-markdown.py https://example.com/docs output.md --user-agent "MyBot/1.0"

  # Without metadata
  python web-to-markdown.py https://example.com/docs output.md --no-metadata

  # With custom timeout
  python web-to-markdown.py https://example.com/docs output.md --timeout 60
        """
    )
    
    parser.add_argument('url', help='URL to convert to Markdown')
    parser.add_argument('output', help='Output Markdown file path')
    parser.add_argument('--timeout', type=int, default=30,
                       help='Request timeout in seconds (default: 30)')
    parser.add_argument('--user-agent', type=str,
                       help='Custom user agent string')
    parser.add_argument('--no-metadata', action='store_true',
                       help='Exclude metadata from output')
    parser.add_argument('--verbose', action='store_true',
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Validate URL
        parsed_url = urlparse(args.url)
        if not parsed_url.scheme or not parsed_url.netloc:
            logger.error("Invalid URL format. Please include protocol (http:// or https://)")
            sys.exit(1)
        
        # Create converter
        converter = WebToMarkdownConverter(
            timeout=args.timeout,
            user_agent=args.user_agent
        )
        
        # Convert URL to Markdown
        success = converter.convert_url_to_markdown(
            args.url,
            args.output,
            include_metadata=not args.no_metadata
        )
        
        if success:
            print(f"✓ Successfully converted {args.url} to {args.output}")
            sys.exit(0)
        else:
            print(f"✗ Failed to convert {args.url}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
