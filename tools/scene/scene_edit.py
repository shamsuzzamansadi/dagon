"""Small, strict helpers for editing a Godot .tscn as text. Every edit asserts that it found exactly what it expected."""
import re
from pathlib import Path


class Scene:
    def __init__(self, path):
        self.path = Path(path)
        self.text = self.path.read_text()

    def save(self):
        self.path.write_text(self.text)

    # ---- resources
    def add_ext(self, rid, res_path, kind="Texture2D"):
        line = f'[ext_resource type="{kind}" path="{res_path}" id="{rid}"]\n'
        if line in self.text:
            return
        assert f'id="{rid}"' not in self.text, rid
        last = list(re.finditer(r'^\[ext_resource [^\n]*\]\n', self.text, re.M))[-1]
        self.text = self.text[: last.end()] + line + self.text[last.end():]

    def add_sub(self, block):
        """Adds a sub_resource block before the first node."""
        header = block.strip().split("\n")[0]
        if header in self.text:
            a = self.text.index(header); b = self.text.index("\n\n", a) + 2
            self.text = self.text[:a] + block.strip() + "\n\n" + self.text[b:]
            return
        first = self.text.index("[node ")
        self.text = self.text[:first] + block.strip() + "\n\n" + self.text[first:]

    # ---- nodes
    def node_span(self, name, parent):
        pattern = r'\[node name="%s" [^\]]*parent="%s"[^\]]*\]\n' % (re.escape(name), re.escape(parent))
        found = list(re.finditer(pattern, self.text))
        assert len(found) == 1, (name, parent, len(found))
        end = self.text.index("\n\n", found[0].start()) + 2
        return found[0].start(), end

    def has_node(self, name, parent):
        return re.search(r'\[node name="%s" [^\]]*parent="%s"[^\]]*\]\n' % (re.escape(name), re.escape(parent)), self.text) is not None

    def node(self, name, parent):
        a, b = self.node_span(name, parent)
        return self.text[a:b]

    def replace_node(self, name, parent, block):
        a, b = self.node_span(name, parent)
        self.text = self.text[:a] + block.strip() + "\n\n" + self.text[b:]

    def remove_node(self, name, parent):
        a, b = self.node_span(name, parent)
        self.text = self.text[:a] + self.text[b:]

    def insert_after(self, name, parent, block):
        _, b = self.node_span(name, parent)
        self.text = self.text[:b] + block.strip() + "\n\n" + self.text[b:]

    def insert_before(self, name, parent, block):
        a, _ = self.node_span(name, parent)
        self.text = self.text[:a] + block.strip() + "\n\n" + self.text[a:]

    def set_prop(self, name, parent, prop, value):
        a, b = self.node_span(name, parent)
        block = self.text[a:b]
        lines = block.rstrip("\n").split("\n")
        for i, line in enumerate(lines):
            if line.startswith(prop + " = "):
                lines[i] = f"{prop} = {value}"
                break
        else:
            lines.append(f"{prop} = {value}")
        self.text = self.text[:a] + "\n".join(lines) + "\n\n" + self.text[b:]

    def del_prop(self, name, parent, prop):
        a, b = self.node_span(name, parent)
        lines = [l for l in self.text[a:b].rstrip("\n").split("\n") if not l.startswith(prop + " = ")]
        self.text = self.text[:a] + "\n".join(lines) + "\n\n" + self.text[b:]

    # ---- clips
    def clip(self, rid):
        return Clip(self, rid)


class Clip:
    def __init__(self, scene, rid):
        self.scene = scene
        self.rid = rid
        header = f'[sub_resource type="Animation" id="{rid}"]\n'
        assert scene.text.count(header) == 1, rid
        self.a = scene.text.index(header)
        self.b = scene.text.index("\n\n", self.a) + 2
        body = scene.text[self.a + len(header): self.b].rstrip("\n")
        first = re.search(r"^tracks/0/", body, re.M)
        self.head = body[: first.start()] if first else body + "\n"
        self.tracks = []
        if first:
            chunks = re.split(r"(?m)^(?=tracks/\d+/type = )", body[first.start():])
            for chunk in chunks:
                if not chunk.strip():
                    continue
                self.tracks.append(re.sub(r"(?m)^tracks/\d+/", "tracks/N/", chunk.rstrip("\n")))

    def path_of(self, track):
        return re.search(r'tracks/N/path = NodePath\("([^"]*)"\)', track).group(1)

    def find(self, path):
        return [i for i, t in enumerate(self.tracks) if self.path_of(t) == path]

    def remove(self, path):
        hits = self.find(path)
        assert len(hits) == 1, (path, hits)
        del self.tracks[hits[0]]

    def rename(self, old, new):
        hits = self.find(old)
        assert len(hits) == 1, (old, hits)
        self.tracks[hits[0]] = self.tracks[hits[0]].replace(f'NodePath("{old}")', f'NodePath("{new}")')

    def set_value(self, path, times, values, transitions=None, update=0):
        """Replaces the value track on this path, or adds it. Values are already Godot text."""
        transitions = transitions or [1] * len(times)
        assert len(times) == len(values) == len(transitions), path
        num = lambda v: ("%g" % v)
        track = "\n".join([
            'tracks/N/type = "value"', "tracks/N/imported = false", "tracks/N/enabled = true",
            f'tracks/N/path = NodePath("{path}")', "tracks/N/interp = 1", "tracks/N/loop_wrap = true", "tracks/N/keys = {",
            f'"times": PackedFloat32Array({", ".join(num(t) for t in times)}),',
            f'"transitions": PackedFloat32Array({", ".join(num(t) for t in transitions)}),',
            f'"update": {update},', f'"values": [{", ".join(values)}]', "}"])
        hits = self.find(path)
        assert len(hits) <= 1, (path, hits)
        if hits:
            self.tracks[hits[0]] = track
        else:
            self.tracks.append(track)

    def save(self):
        body = self.head + "\n".join(t.replace("tracks/N/", f"tracks/{i}/") for i, t in enumerate(self.tracks)) + "\n\n" if self.tracks else self.head.rstrip("\n") + "\n\n"
        header = f'[sub_resource type="Animation" id="{self.rid}"]\n'
        self.scene.text = self.scene.text[: self.a] + header + body + self.scene.text[self.b:]


def v2(x, y):
    return "Vector2(%g, %g)" % (x, y)


def col(r, g, b, a):
    return "Color(%g, %g, %g, %g)" % (r, g, b, a)
