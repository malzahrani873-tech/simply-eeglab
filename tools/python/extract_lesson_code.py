"""
extract_lesson_code.py - copy the MATLAB code of each lesson into runnable .m files.

For every lesson in lessons/en:
  <slug>_start.m   the Starting point script (frontmatter field startingPoint.script)
  <slug>_<n>.m     each ```matlab block of the lesson, in order
Each block is compared with lessons/ar, where the code must be identical.

The output is a run copy only. The lesson is the reference; extract again after any edit.

Usage:
  python3 -I extract_lesson_code.py --lessons /path/to/lessons --out /path/to/tools/matlab/lessons
"""
import argparse
import os
import re

FENCE = re.compile(r"```matlab\n(.*?)```", re.S)


def blocks(path):
    text = open(path, encoding="utf-8").read()
    front = text.split("\n---", 2)[0] if text.startswith("---") else ""
    start = ""
    m = re.search(r"^  script: \|\n((?:    .*\n|\n)+)", front + "\n", re.M)
    if m:
        start = "\n".join(line[4:] for line in m.group(1).rstrip().splitlines()) + "\n"
    body = text[len(front):]
    return start, FENCE.findall(body)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lessons", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name in sorted(os.listdir(os.path.join(a.lessons, "en"))):
        if not name.endswith(".md"):
            continue
        slug = re.sub(r"^\d+-\d+-", "", name[:-3])
        en_start, en_blocks = blocks(os.path.join(a.lessons, "en", name))
        ar_path = os.path.join(a.lessons, "ar", name)
        if os.path.exists(ar_path):
            ar_start, ar_blocks = blocks(ar_path)
            if (ar_start, ar_blocks) != (en_start, en_blocks):
                print(f"warning: code of {slug} differs between ar and en")
        head = f"% Copied from lessons/en/{name}. The lesson is the reference.\n"
        files = []
        if en_start:
            files.append((f"{slug}_start.m", "% Starting point\n" + en_start))
        for i, b in enumerate(en_blocks, 1):
            files.append((f"{slug}_{i}.m", b))
        for fname, code in files:
            open(os.path.join(a.out, fname.replace("-", "_")), "w", encoding="utf-8").write(head + code)
            print(fname.replace("-", "_"))


if __name__ == "__main__":
    main()
