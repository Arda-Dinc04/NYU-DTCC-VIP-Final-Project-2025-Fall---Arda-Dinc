#!/usr/bin/env python3
"""
SBOM Merger: Merges dynamic dependencies captured by strace into static SBOM

This script:
1. Reads a static SBOM (CycloneDX format)
2. Reads dynamic libraries JSON (from strace parsing)
3. Merges them into a final SBOM with all dependencies
"""

import json
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any


def load_json(filepath: str) -> Dict:
    """Load JSON file."""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}", file=sys.stderr)
        sys.exit(1)


def save_json(data: Dict, filepath: str) -> None:
    """Save JSON file with pretty formatting."""
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)


def create_component_from_dynamic(lib: Dict) -> Dict:
    """Convert dynamic library info to CycloneDX component format."""
    component = {
        "type": lib.get("type", "library"),
        "name": lib.get("name", "unknown"),
        "version": lib.get("version", "unknown"),
    }
    
    # Add group if available (Maven)
    if "group" in lib and lib["group"]:
        component["group"] = lib["group"]
    
    # Add PURL
    if "purl" in lib:
        component["purl"] = lib["purl"]
        component["bom-ref"] = lib["purl"]
    else:
        # Generate bom-ref
        name = lib.get("name", "unknown")
        version = lib.get("version", "unknown")
        component["bom-ref"] = f"pkg:generic/{name}@{version}"
        component["purl"] = component["bom-ref"]
    
    # Add hashes
    if "hashes" in lib:
        component["hashes"] = []
        for hash_obj in lib["hashes"]:
            if hash_obj.get("content"):  # Only add non-empty hashes
                component["hashes"].append({
                    "alg": hash_obj.get("alg", "SHA-1"),
                    "content": hash_obj["content"]
                })
    
    # Add properties
    properties = lib.get("properties", [])
    if "path" in lib:
        properties.append({
            "name": "dynamic:filePath",
            "value": lib["path"]
        })
    component["properties"] = properties
    
    return component


def merge_components(static_components: List[Dict], dynamic_libs: List[Dict]) -> List[Dict]:
    """Merge static and dynamic components, avoiding duplicates."""
    merged = []
    seen_purls = set()
    seen_bom_refs = set()
    
    # Add static components first
    for comp in static_components:
        bom_ref = comp.get("bom-ref", "")
        purl = comp.get("purl", "")
        
        if bom_ref:
            seen_bom_refs.add(bom_ref)
        if purl:
            seen_purls.add(purl)
        
        merged.append(comp)
    
    # Add dynamic components (avoid duplicates)
    for lib in dynamic_libs:
        component = create_component_from_dynamic(lib)
        bom_ref = component.get("bom-ref", "")
        purl = component.get("purl", "")
        
        # Check for duplicates
        is_duplicate = False
        if bom_ref and bom_ref in seen_bom_refs:
            is_duplicate = True
        elif purl and purl in seen_purls:
            is_duplicate = True
        else:
            # Check by name+version
            for existing in merged:
                if (existing.get("name") == component.get("name") and
                    existing.get("version") == component.get("version") and
                    existing.get("group", "") == component.get("group", "")):
                    is_duplicate = True
                    break
        
        if not is_duplicate:
            merged.append(component)
            if bom_ref:
                seen_bom_refs.add(bom_ref)
            if purl:
                seen_purls.add(purl)
    
    return merged


def update_metadata_tools(metadata: Dict) -> Dict:
    """Update metadata to include our tool."""
    if "tools" not in metadata:
        metadata["tools"] = {}
    
    if "components" not in metadata["tools"]:
        metadata["tools"]["components"] = []
    
    # Add our tool
    our_tool = {
        "type": "application",
        "name": "sbom-dynamic-capture",
        "version": "1.0.0",
        "author": "NYU DTCC VIP"
    }
    
    # Check if already added
    tool_names = [t.get("name") for t in metadata["tools"]["components"]]
    if "sbom-dynamic-capture" not in tool_names:
        metadata["tools"]["components"].append(our_tool)
    
    return metadata


def merge_sboms(static_sbom: Dict, dynamic_libs: List[Dict]) -> Dict:
    """Merge static SBOM and dynamic libraries into final SBOM."""
    # Start with static SBOM structure
    final_sbom = static_sbom.copy()
    
    # Update metadata
    if "metadata" not in final_sbom:
        final_sbom["metadata"] = {}
    
    final_sbom["metadata"] = update_metadata_tools(final_sbom["metadata"])
    
    # Update timestamp
    final_sbom["metadata"]["timestamp"] = datetime.utcnow().isoformat() + "Z"
    
    # Merge components
    static_components = final_sbom.get("components", [])
    final_sbom["components"] = merge_components(static_components, dynamic_libs)
    
    # Update dependencies section if it exists
    # (We could add dependency relationships here, but keeping it simple for now)
    
    return final_sbom


def main():
    if len(sys.argv) != 4:
        print("Usage: merge-sbom.py <static-sbom.json> <dynamic-libs.json> <output-sbom.json>", file=sys.stderr)
        sys.exit(1)
    
    static_sbom_path = sys.argv[1]
    dynamic_libs_path = sys.argv[2]
    output_sbom_path = sys.argv[3]
    
    # Load files
    static_sbom = load_json(static_sbom_path)
    dynamic_libs = load_json(dynamic_libs_path)
    
    if not isinstance(dynamic_libs, list):
        print("Error: dynamic-libs.json should be a JSON array", file=sys.stderr)
        sys.exit(1)
    
    # Merge
    final_sbom = merge_sboms(static_sbom, dynamic_libs)
    
    # Save
    save_json(final_sbom, output_sbom_path)
    
    print(f"Successfully merged {len(static_sbom.get('components', []))} static and {len(dynamic_libs)} dynamic components")
    print(f"Final SBOM has {len(final_sbom.get('components', []))} components")


if __name__ == "__main__":
    main()

