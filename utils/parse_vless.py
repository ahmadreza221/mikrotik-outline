#!/usr/bin/env python3
"""
VLESS URL Parser for MikroTik RouterOS
Parses VLESS URLs and extracts configuration parameters for Xray container setup.
"""

import urllib.parse
import base64
import json
import sys
import re
from typing import Dict, Optional


def parse_vless_url(vless_url: str) -> Dict[str, str]:
    """
    Parse a VLESS URL and extract all configuration parameters.
    
    Args:
        vless_url: Complete VLESS URL string
        
    Returns:
        Dictionary containing all parsed parameters
        
    Example:
        vless://e73c748e-19fa-4618-a4d9-c7dfb22c66e7@threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link:443?type=tcp&security=reality&pbk=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU&fp=chrome&sni=yahoo.com&sid=ad2e&spx=%2F#🇩🇪3-50.00GB-246175259-LK
    """
    
    # Remove the vless:// prefix
    if not vless_url.startswith('vless://'):
        raise ValueError("Invalid VLESS URL: must start with 'vless://'")
    
    # Split the URL into parts
    url_without_prefix = vless_url[8:]  # Remove 'vless://'
    
    # Split by @ to separate UUID from the rest
    if '@' not in url_without_prefix:
        raise ValueError("Invalid VLESS URL: missing @ separator")
    
    uuid_part, rest = url_without_prefix.split('@', 1)
    
    # Split by ? to separate host:port from query parameters
    if '?' in rest:
        host_port_part, query_part = rest.split('?', 1)
    else:
        host_port_part = rest
        query_part = ""
    
    # Split by # to separate query from fragment (comment)
    if '#' in query_part:
        query_part, fragment = query_part.split('#', 1)
    else:
        fragment = ""
    
    # Parse host:port
    if ':' in host_port_part:
        host, port = host_port_part.rsplit(':', 1)
    else:
        host = host_port_part
        port = "443"  # Default port
    
    # Parse query parameters
    query_params = urllib.parse.parse_qs(query_part)
    
    # Extract individual parameters
    result = {
        'uuid': uuid_part,
        'host': host,
        'port': port,
        'type': query_params.get('type', ['tcp'])[0],
        'security': query_params.get('security', ['none'])[0],
        'pbk': query_params.get('pbk', [''])[0],
        'fp': query_params.get('fp', ['chrome'])[0],
        'sni': query_params.get('sni', [''])[0],
        'sid': query_params.get('sid', [''])[0],
        'spx': query_params.get('spx', ['/'])[0],
        'comment': fragment
    }
    
    return result


def format_for_mikrotik(parsed_data: Dict[str, str]) -> str:
    """
    Format parsed data for MikroTik RouterOS environment variables.
    
    Args:
        parsed_data: Dictionary from parse_vless_url
        
    Returns:
        Formatted string for MikroTik environment variables
    """
    
    env_vars = [
        f"UUID={parsed_data['uuid']}",
        f"HOST={parsed_data['host']}",
        f"PORT={parsed_data['port']}",
        f"TYPE={parsed_data['type']}",
        f"SECURITY={parsed_data['security']}",
        f"PBK={parsed_data['pbk']}",
        f"FP={parsed_data['fp']}",
        f"SNI={parsed_data['sni']}",
        f"SID={parsed_data['sid']}",
        f"SPX={parsed_data['spx']}",
        f"COMMENT={parsed_data['comment']}"
    ]
    
    return " ".join(env_vars)


def main():
    """Main function for command-line usage."""
    
    if len(sys.argv) != 2:
        print("Usage: python parse_vless.py <vless_url>")
        print("\nExample:")
        print('python parse_vless.py "vless://e73c748e-19fa-4618-a4d9-c7dfb22c66e7@threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link:443?type=tcp&security=reality&pbk=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU&fp=chrome&sni=yahoo.com&sid=ad2e&spx=%2F#🇩🇪3-50.00GB-246175259-LK"')
        sys.exit(1)
    
    vless_url = sys.argv[1]
    
    try:
        # Parse the URL
        parsed = parse_vless_url(vless_url)
        
        # Output as JSON
        print("Parsed VLESS URL:")
        print(json.dumps(parsed, indent=2))
        
        # Output for MikroTik
        print("\nMikroTik Environment Variables:")
        print(format_for_mikrotik(parsed))
        
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 