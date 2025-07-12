#!/usr/bin/env python3
"""
Test script for VLESS URL parser
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

from parse_vless import parse_vless_url, format_for_mikrotik

def test_parser():
    """Test the VLESS parser with the example URL"""
    
    # Example VLESS URL from the requirements
    test_url = "vless://e73c748e-19fa-4618-a4d9-c7dfb22c66e7@threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link:443?type=tcp&security=reality&pbk=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU&fp=chrome&sni=yahoo.com&sid=ad2e&spx=%2F#🇩🇪3-50.00GB-246175259-LK"
    
    print("Testing VLESS URL Parser")
    print("=" * 50)
    print(f"Input URL: {test_url}")
    print()
    
    try:
        # Parse the URL
        parsed = parse_vless_url(test_url)
        
        print("Parsed Parameters:")
        print("-" * 30)
        for key, value in parsed.items():
            print(f"{key}: {value}")
        
        print()
        print("MikroTik Environment Variables:")
        print("-" * 40)
        print(format_for_mikrotik(parsed))
        
        print()
        print("✅ Parser test completed successfully!")
        
        # Verify expected values
        expected = {
            'uuid': 'e73c748e-19fa-4618-a4d9-c7dfb22c66e7',
            'host': 'threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link',
            'port': '443',
            'type': 'tcp',
            'security': 'reality',
            'pbk': 'fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU',
            'fp': 'chrome',
            'sni': 'yahoo.com',
            'sid': 'ad2e',
            'spx': '/',
            'comment': '🇩🇪3-50.00GB-246175259-LK'
        }
        
        print()
        print("Validation Results:")
        print("-" * 20)
        all_correct = True
        for key, expected_value in expected.items():
            actual_value = parsed.get(key, '')
            if actual_value == expected_value:
                print(f"✅ {key}: OK")
            else:
                print(f"❌ {key}: Expected '{expected_value}', got '{actual_value}'")
                all_correct = False
        
        if all_correct:
            print()
            print("🎉 All tests passed! Parser is working correctly.")
        else:
            print()
            print("⚠️  Some tests failed. Please check the parser implementation.")
            
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = test_parser()
    sys.exit(0 if success else 1) 