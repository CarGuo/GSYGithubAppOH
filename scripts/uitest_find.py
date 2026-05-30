#!/usr/bin/env python3
"""
解析 hdc uitest dumpLayout 出来的 JSON 树，按 id 找节点中心坐标。
用法：
  python3 scripts/uitest_find.py <layout.json> <id>
输出：
  <cx> <cy>   （空格分隔，找不到时退出码 1）
"""
import json
import sys


def walk(node, target_id):
    attrs = node.get("attributes", {}) or {}
    if attrs.get("id") == target_id:
        return attrs
    for c in node.get("children", []) or []:
        r = walk(c, target_id)
        if r is not None:
            return r
    return None


def parse_bounds(b):
    # 形如 "[321,1207][1098,1452]"
    nums = [int(x) for x in b.replace("[", " ").replace("]", " ").replace(",", " ").split()]
    if len(nums) != 4:
        return None
    x1, y1, x2, y2 = nums
    return (x1 + x2) // 2, (y1 + y2) // 2


def find_by_text(node, text):
    attrs = node.get("attributes", {}) or {}
    if attrs.get("text") == text:
        return attrs
    for c in node.get("children", []) or []:
        r = find_by_text(c, text)
        if r is not None:
            return r
    return None


def find_by_placeholder(node, ph):
    attrs = node.get("attributes", {}) or {}
    if attrs.get("description", "") == ph or attrs.get("placeholder", "") == ph or attrs.get("hint", "") == ph:
        return attrs
    # 兼容：放宽到 text 包含
    if ph in attrs.get("text", "") and attrs.get("type", "").lower().endswith("textinput"):
        return attrs
    for c in node.get("children", []) or []:
        r = find_by_placeholder(c, ph)
        if r is not None:
            return r
    return None


def main():
    if len(sys.argv) < 3:
        print("usage: uitest_find.py <layout.json> <id|text:OK|ph:ghp_xxxx>", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]
    sel = sys.argv[2]
    tree = json.load(open(path))
    if sel.startswith("text:"):
        attrs = find_by_text(tree, sel[5:])
    elif sel.startswith("ph:"):
        attrs = find_by_placeholder(tree, sel[3:])
    else:
        attrs = walk(tree, sel)
    if attrs is None:
        print(f"NOT_FOUND: {sel}", file=sys.stderr)
        sys.exit(1)
    b = attrs.get("bounds", "")
    p = parse_bounds(b)
    if not p:
        print(f"BAD_BOUNDS: {b}", file=sys.stderr)
        sys.exit(1)
    print(f"{p[0]} {p[1]}")


if __name__ == "__main__":
    main()
