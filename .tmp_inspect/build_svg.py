import re, pathlib
src = pathlib.Path('/var/folders/_l/69c14t4n1tgbl14j9fskcjd40000gn/T/aicoding-text-field/a8958b3e-39ca-439a-b9a6-da4bb8ae9ce3')
items = {
  'help_thumb_up.svg': 'text-field-content-cf292a20-99bf-4e70-a7c2-f85970bf78be.txt',
  'help_thumb_down.svg': 'text-field-content-45959acc-6c0f-4768-ab47-83492181d454.txt',
}
out = pathlib.Path('assets/images/svg')
for name, f in items.items():
    lines = (src / f).read_text().splitlines()
    svg_open = next(l for l in lines if l.startswith('<svg'))
    rects = [l for l in lines if l.startswith('<rect')]
    img = next(l for l in lines if l.startswith('<image'))
    m = re.match(r'<image id="[^"]*" width="(\d+)" height="(\d+)" preserveAspectRatio="([^"]*)" xlink:href="(data:image/png;base64,[^"]*)"', img)
    w, h, par, href = int(m.group(1)), int(m.group(2)), m.group(3), m.group(4)
    use = next(l for l in lines if l.startswith('<use'))
    t = re.search(r'transform="matrix\(([^)]*)\)"', use).group(1).split()
    sx, ty = float(t[0]), float(t[5])
    dx, dy = float(t[4]), float(t[5])
    nw, nh = w * sx, h * sx
    body = [
        svg_open,
        rects[0],
        '<image width="%g" height="%g" x="%g" y="%g" preserveAspectRatio="%s" xlink:href="%s"/>' % (nw, nh, dx, dy, par, href),
        rects[1],
        '</svg>',
    ]
    (out / name).write_text('\n'.join(body) + '\n')
    print(name, 'icon', nw, 'x', nh, 'at', dx, dy, 'bytes', (out / name).stat().st_size)
