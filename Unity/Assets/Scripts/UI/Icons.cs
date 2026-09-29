using System.Collections.Generic;
using UnityEngine;

namespace HueHaven
{
    /// <summary>
    /// Geometric icons drawn as vector shapes — port of scripts/Icon.gd.
    /// Icons are drawn in white; tint them with <c>graphic.color</c>.
    /// </summary>
    public static class Icons
    {
        const float StrokeW = 2.5f;

        public static void Draw(VectorGraphic g, string name, Vector2 c, float size)
        {
            Color w = Color.white;
            switch (name)
            {
                case "back": Back(g, c, size, w); break;
                case "next": Next(g, c, size, w); break;
                case "settings": Settings(g, c, size, w); break;
                case "undo": ArrowArc(g, c, size, w, true); break;
                case "restart": ArrowArc(g, c, size, w, false); break;
                case "hint": Hint(g, c, size, w); break;
                case "close": Close(g, c, size, w); break;
                case "play": Play(g, c, size, w); break;
                case "star": Star(g, c, size, w); break;
                case "lock": Lock(g, c, size, w); break;
            }
        }

        static void Back(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float w = size * 0.55f, h = size * 0.40f;
            var left = c + new Vector2(-w * 0.5f, 0);
            var right = c + new Vector2(w * 0.5f, 0);
            g.Line(left, right, col, StrokeW);
            g.Line(left, left + new Vector2(h * 0.5f, -h * 0.5f), col, StrokeW);
            g.Line(left, left + new Vector2(h * 0.5f, h * 0.5f), col, StrokeW);
        }

        static void Next(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float w = size * 0.55f, h = size * 0.40f;
            var left = c + new Vector2(-w * 0.5f, 0);
            var right = c + new Vector2(w * 0.5f, 0);
            g.Line(left, right, col, StrokeW);
            g.Line(right, right + new Vector2(-h * 0.5f, -h * 0.5f), col, StrokeW);
            g.Line(right, right + new Vector2(-h * 0.5f, h * 0.5f), col, StrokeW);
        }

        // Gear: 8 notches around a hub.
        static void Settings(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float outer = size * 0.42f, inner = size * 0.32f, hub = size * 0.16f;
            const int notches = 8;
            int steps = notches * 4;
            var pts = new List<Vector2>(steps);
            for (int i = 0; i < steps; i++)
            {
                float a = Mathf.PI * 2f * i / steps;
                float r = (i % 4 < 2) ? outer : inner;
                pts.Add(c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r);
            }
            g.Polyline(pts, col, StrokeW, true);
            g.CircleOutline(c, hub, col, StrokeW);
        }

        // 252° arc with an arrowhead — counter-clockwise for undo, clockwise for restart.
        static void ArrowArc(VectorGraphic g, Vector2 c, float size, Color col, bool counterClockwise)
        {
            float r = size * 0.32f;
            float start = -Mathf.PI * 0.5f;
            float span = Mathf.PI * 1.4f;
            const int segs = 18;
            var pts = new Vector2[segs + 1];
            for (int i = 0; i <= segs; i++)
            {
                float t = (float)i / segs;
                float a = counterClockwise ? start - span * t : start + span * t;
                pts[i] = c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r;
            }
            g.Polyline(pts, col, StrokeW, false);

            Vector2 end = pts[segs], prev = pts[segs - 1];
            Vector2 tangent = (end - prev).normalized;
            Vector2 perp = new Vector2(-tangent.y, tangent.x);
            float head = size * 0.18f;
            g.Line(end, end - tangent * head + perp * head * 0.6f, col, StrokeW);
            g.Line(end, end - tangent * head - perp * head * 0.6f, col, StrokeW);
        }

        // Lightbulb: circle, filament, screw cap.
        static void Hint(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float bulbR = size * 0.28f;
            var bulb = c + new Vector2(0, -size * 0.05f);
            g.CircleOutline(bulb, bulbR, col, StrokeW);
            float filY = bulb.y + bulbR * 0.2f;
            g.Line(new Vector2(bulb.x - bulbR * 0.45f, filY), new Vector2(bulb.x + bulbR * 0.45f, filY), col, StrokeW * 0.7f);
            float baseY = bulb.y + bulbR + 2f;
            float baseW = bulbR * 0.9f;
            g.FillRect(c.x - baseW * 0.5f, baseY, baseW, 3f, col);
            g.FillRect(c.x - baseW * 0.35f, baseY + 4f, baseW * 0.7f, 2f, col);
        }

        static void Close(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float s = size * 0.30f;
            g.Line(c + new Vector2(-s, -s), c + new Vector2(s, s), col, StrokeW);
            g.Line(c + new Vector2(-s, s), c + new Vector2(s, -s), col, StrokeW);
        }

        static void Play(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float r = size * 0.35f;
            g.FillPolygon(new[]
            {
                c + new Vector2(-r * 0.6f, -r),
                c + new Vector2(r, 0),
                c + new Vector2(-r * 0.6f, r),
            }, col);
        }

        // Filled five-point star.
        static void Star(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float outer = size * 0.40f, inner = size * 0.16f;
            var pts = new Vector2[10];
            for (int i = 0; i < 10; i++)
            {
                float a = -Mathf.PI * 0.5f + Mathf.PI * 2f * i / 10f;
                float r = (i % 2 == 0) ? outer : inner;
                pts[i] = c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r;
            }
            g.FillPolygon(pts, col);
        }

        // Padlock: body + shackle arc.
        static void Lock(VectorGraphic g, Vector2 c, float size, Color col)
        {
            float bodyW = size * 0.42f, bodyH = size * 0.34f;
            float bx = c.x - bodyW * 0.5f, by = c.y - bodyH * 0.3f;
            g.FillRect(bx, by, bodyW, bodyH, col);
            float arcR = bodyW * 0.35f;
            var arcCentre = new Vector2(c.x, by);
            // Godot's y-down arc from -PI to 0 is the upper half; same here.
            g.Arc(arcCentre, arcR, -Mathf.PI, 0f, col, StrokeW, 12);
        }
    }
}
