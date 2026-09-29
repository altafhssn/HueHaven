using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>
    /// A uGUI graphic that batches simple 2D shapes (fills, thick anti-aliased lines,
    /// polygons) into one mesh. This is the equivalent of Godot's CanvasItem draw_* calls.
    /// Coordinates are local to the RectTransform with the origin at the top-left and
    /// Y pointing DOWN, so Godot-era layout maths ports over unchanged.
    /// Shapes are drawn in white by convention and tinted through <see cref="Graphic.color"/>.
    /// </summary>
    [RequireComponent(typeof(CanvasRenderer))]
    public class VectorGraphic : MaskableGraphic
    {
        readonly List<Vector2> _pos = new List<Vector2>();
        readonly List<Color32> _col = new List<Color32>();
        readonly List<int> _idx = new List<int>();

        /// <summary>Width of the alpha fringe used to fake anti-aliasing on strokes.</summary>
        public float Feather = 0.75f;

        public void Clear()
        {
            _pos.Clear(); _col.Clear(); _idx.Clear();
        }

        /// <summary>Push accumulated geometry to the canvas.</summary>
        public void Commit() { SetVerticesDirty(); }

        int AddVert(Vector2 p, Color c)
        {
            _pos.Add(p);
            _col.Add(c);
            return _pos.Count - 1;
        }

        void Tri(int a, int b, int c) { _idx.Add(a); _idx.Add(b); _idx.Add(c); }

        void Quad(int a, int b, int c, int d)
        {
            Tri(a, b, c);
            Tri(a, c, d);
        }

        // --- Fills ---

        public void FillRect(float x, float y, float w, float h, Color c)
        {
            FillGradientRect(x, y, w, h, c, c);
        }

        public void FillGradientRect(float x, float y, float w, float h, Color top, Color bottom)
        {
            int a = AddVert(new Vector2(x, y), top);
            int b = AddVert(new Vector2(x + w, y), top);
            int c = AddVert(new Vector2(x + w, y + h), bottom);
            int d = AddVert(new Vector2(x, y + h), bottom);
            Quad(a, b, c, d);
        }

        /// <summary>Convex or star-shaped polygon, fan-triangulated from its centroid.</summary>
        public void FillPolygon(IList<Vector2> pts, Color c)
        {
            if (pts.Count < 3) return;
            Vector2 centre = Vector2.zero;
            for (int i = 0; i < pts.Count; i++) centre += pts[i];
            centre /= pts.Count;
            int ci = AddVert(centre, c);
            int first = -1, prev = -1;
            for (int i = 0; i < pts.Count; i++)
            {
                int v = AddVert(pts[i], c);
                if (first < 0) first = v;
                if (prev >= 0) Tri(ci, prev, v);
                prev = v;
            }
            Tri(ci, prev, first);
        }

        public void FillCircle(Vector2 centre, float radius, Color c, int segments = 24)
        {
            var pts = new List<Vector2>(segments);
            for (int i = 0; i < segments; i++)
            {
                float a = Mathf.PI * 2f * i / segments;
                pts.Add(centre + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * radius);
            }
            FillPolygon(pts, c);
        }

        /// <summary>Vertical-gradient rounded rectangle.</summary>
        public void FillRoundedGradient(float x, float y, float w, float h, float radius, Color top, Color bottom, int cornerSegs = 6)
        {
            float r = Mathf.Min(radius, Mathf.Min(w, h) * 0.5f);
            var pts = new List<Vector2>();
            AddArc(pts, new Vector2(x + w - r, y + r), r, -90f, 0f, cornerSegs);
            AddArc(pts, new Vector2(x + w - r, y + h - r), r, 0f, 90f, cornerSegs);
            AddArc(pts, new Vector2(x + r, y + h - r), r, 90f, 180f, cornerSegs);
            AddArc(pts, new Vector2(x + r, y + r), r, 180f, 270f, cornerSegs);

            int ci = AddVert(new Vector2(x + w * 0.5f, y + h * 0.5f), Color.Lerp(top, bottom, 0.5f));
            int first = -1, prev = -1;
            foreach (var p in pts)
            {
                int v = AddVert(p, Color.Lerp(top, bottom, Mathf.Clamp01((p.y - y) / Mathf.Max(1f, h))));
                if (first < 0) first = v;
                if (prev >= 0) Tri(ci, prev, v);
                prev = v;
            }
            Tri(ci, prev, first);
        }

        static void AddArc(List<Vector2> pts, Vector2 centre, float r, float fromDeg, float toDeg, int segs)
        {
            for (int i = 0; i <= segs; i++)
            {
                float a = Mathf.Deg2Rad * Mathf.Lerp(fromDeg, toDeg, (float)i / segs);
                pts.Add(centre + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r);
            }
        }

        // --- Strokes ---

        public void Line(Vector2 a, Vector2 b, Color c, float width)
        {
            Polyline(new[] { a, b }, c, width, false);
        }

        public void Arc(Vector2 centre, float radius, float fromRad, float toRad, Color c, float width, int segments = 16)
        {
            var pts = new Vector2[segments + 1];
            for (int i = 0; i <= segments; i++)
            {
                float a = Mathf.Lerp(fromRad, toRad, (float)i / segments);
                pts[i] = centre + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * radius;
            }
            Polyline(pts, c, width, false);
        }

        public void CircleOutline(Vector2 centre, float radius, Color c, float width, int segments = 18)
        {
            var pts = new Vector2[segments];
            for (int i = 0; i < segments; i++)
            {
                float a = Mathf.PI * 2f * i / segments;
                pts[i] = centre + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * radius;
            }
            Polyline(pts, c, width, true);
        }

        public void RectOutline(float x, float y, float w, float h, Color c, float width)
        {
            Polyline(new[] { new Vector2(x, y), new Vector2(x + w, y), new Vector2(x + w, y + h), new Vector2(x, y + h) }, c, width, true);
        }

        /// <summary>Mitred thick polyline with a 1-ring alpha fringe for smooth edges.</summary>
        public void Polyline(IList<Vector2> pts, Color c, float width, bool closed)
        {
            // Drop consecutive duplicates so normals stay finite.
            var p = new List<Vector2>(pts.Count);
            for (int i = 0; i < pts.Count; i++)
                if (p.Count == 0 || (pts[i] - p[p.Count - 1]).sqrMagnitude > 1e-6f) p.Add(pts[i]);
            if (closed && p.Count > 1 && (p[0] - p[p.Count - 1]).sqrMagnitude < 1e-6f) p.RemoveAt(p.Count - 1);
            int n = p.Count;
            if (n < 2) return;

            float hw = width * 0.5f;
            Color clear = c; clear.a = 0f;
            int rows = n;
            int[] baseIdx = new int[rows];

            for (int i = 0; i < n; i++)
            {
                bool hasPrev = closed || i > 0;
                bool hasNext = closed || i < n - 1;
                Vector2 dPrev = hasPrev ? (p[i] - p[(i - 1 + n) % n]).normalized : Vector2.zero;
                Vector2 dNext = hasNext ? (p[(i + 1) % n] - p[i]).normalized : Vector2.zero;
                Vector2 nPrev = new Vector2(-dPrev.y, dPrev.x);
                Vector2 nNext = new Vector2(-dNext.y, dNext.x);

                Vector2 m;
                float scale = 1f;
                if (!hasPrev) m = nNext;
                else if (!hasNext) m = nPrev;
                else
                {
                    m = nPrev + nNext;
                    if (m.sqrMagnitude < 1e-6f) m = nNext;
                    m.Normalize();
                    float dot = Vector2.Dot(m, nNext);
                    scale = dot > 0.5f ? 1f / dot : 2f; // clamp spikes on tight corners
                }

                float o = hw * scale;
                float f = Feather;
                baseIdx[i] = AddVert(p[i] - m * (o + f), clear);
                AddVert(p[i] - m * o, c);
                AddVert(p[i] + m * o, c);
                AddVert(p[i] + m * (o + f), clear);
            }

            int segCount = closed ? n : n - 1;
            for (int i = 0; i < segCount; i++)
            {
                int a = baseIdx[i], b = baseIdx[(i + 1) % n];
                for (int k = 0; k < 3; k++) Quad(a + k, b + k, b + k + 1, a + k + 1);
            }
        }

        // --- Mesh output ---

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            Rect r = rectTransform.rect;
            Color32 tint = color;
            for (int i = 0; i < _pos.Count; i++)
            {
                Color32 vc = _col[i];
                var v = UIVertex.simpleVert;
                v.position = new Vector3(r.xMin + _pos[i].x, r.yMax - _pos[i].y, 0f);
                v.color = new Color32(
                    (byte)(vc.r * tint.r / 255), (byte)(vc.g * tint.g / 255),
                    (byte)(vc.b * tint.b / 255), (byte)(vc.a * tint.a / 255));
                v.uv0 = Vector2.zero;
                vh.AddVert(v);
            }
            for (int i = 0; i + 2 < _idx.Count; i += 3) vh.AddTriangle(_idx[i], _idx[i + 1], _idx[i + 2]);
        }
    }
}
