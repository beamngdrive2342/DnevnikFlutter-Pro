import json
from pathlib import Path

analysis = json.loads(Path('graphify-out/.graphify_analysis.json').read_text(encoding="utf-8"))
graph = json.loads(Path('graphify-out/graph.json').read_text(encoding="utf-8"))

# Create map from node ID to node label/metadata
node_map = {n['id']: n for n in graph['nodes']}

print(f"Total communities: {len(analysis['communities'])}")

for cid, nodes in sorted(analysis['communities'].items(), key=lambda x: int(x[0])):
    print(f"\nCommunity {cid} ({len(nodes)} nodes):")
    # Show first 8 nodes
    for nid in nodes[:8]:
        n = node_map.get(nid, {})
        label = n.get('label', nid)
        ftype = n.get('file_type', 'unknown')
        print(f"  - {label} ({nid}) [{ftype}]")
    if len(nodes) > 8:
        print(f"  ... and {len(nodes) - 8} more")
