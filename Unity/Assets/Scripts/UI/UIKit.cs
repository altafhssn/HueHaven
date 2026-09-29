using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>One visual state of a <see cref="StyledButton"/>.</summary>
    public struct Skin
    {
        public Color Fill, Border, Text;
        public Skin(Color fill, Color border, Color text) { Fill = fill; Border = border; Text = text; }
    }

    /// <summary>Normal / hover / pressed / disabled skins, mirroring Style.style_button().</summary>
    public sealed class ButtonTheme
    {
        public Skin Normal, Hover, Pressed, Disabled;

        public static ButtonTheme Secondary()
        {
            return new ButtonTheme
            {
                Normal = new Skin(Palette.BtnBg, Palette.BtnBorder, Palette.Text),
                Hover = new Skin(Palette.BtnBgHover, Palette.Accent, Palette.Text),
                Pressed = new Skin(Palette.BtnBgPressed, Palette.BtnBorder, Palette.Text),
                Disabled = new Skin(Palette.BtnDisabledBg, Palette.BtnDisabledBorder, Palette.TextDim),
            };
        }

        public static ButtonTheme Primary()
        {
            return new ButtonTheme
            {
                Normal = new Skin(Palette.Accent, Palette.Accent, Palette.TextOnAccent),
                Hover = new Skin(Palette.AccentHi, Palette.AccentHi, Palette.TextOnAccent),
                Pressed = new Skin(Palette.AccentDim, Palette.Accent, Palette.TextOnAccent),
                Disabled = new Skin(Palette.BtnDisabledBg, Palette.BtnDisabledBorder, Palette.TextDim),
            };
        }

        /// <summary>Custom base colours with the standard lighten/darken state ramp (level tiles).</summary>
        public static ButtonTheme FromBase(Color bg, Color border, Color text, Color disabledText)
        {
            return new ButtonTheme
            {
                Normal = new Skin(bg, border, text),
                Hover = new Skin(Palette.Lightened(bg, 0.08f), Palette.Accent, text),
                Pressed = new Skin(Palette.Darkened(bg, 0.10f), border, text),
                Disabled = new Skin(bg, border, disabledText),
            };
        }
    }

    /// <summary>Button with a rounded fill + border and state colours. Fires on release-inside.</summary>
    public sealed class StyledButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler,
        IPointerEnterHandler, IPointerExitHandler, IPointerClickHandler
    {
        public Image Border, Fill;
        public Text Label;
        public Graphic IconTint;
        public ButtonTheme Theme = ButtonTheme.Secondary();
        public Action OnClick;

        bool _interactable = true, _over, _down;

        public bool Interactable
        {
            get { return _interactable; }
            set { _interactable = value; Refresh(); }
        }

        public void Refresh()
        {
            Skin s = !_interactable ? Theme.Disabled : _down ? Theme.Pressed : _over ? Theme.Hover : Theme.Normal;
            if (Border != null) Border.color = s.Border;
            if (Fill != null) Fill.color = s.Fill;
            if (Label != null) Label.color = s.Text;
            if (IconTint != null) IconTint.color = s.Text;
        }

        public void OnPointerDown(PointerEventData e) { _down = true; Refresh(); }
        public void OnPointerUp(PointerEventData e) { _down = false; Refresh(); }
        public void OnPointerEnter(PointerEventData e) { _over = true; Refresh(); }
        public void OnPointerExit(PointerEventData e) { _over = false; _down = false; Refresh(); }

        public void OnPointerClick(PointerEventData e)
        {
            if (_interactable && OnClick != null) OnClick();
        }
    }

    /// <summary>Forwards pointer-down events (used for tapping tubes).</summary>
    public sealed class TapArea : MonoBehaviour, IPointerDownHandler
    {
        public Action<PointerEventData> OnDown;
        public void OnPointerDown(PointerEventData e) { if (OnDown != null) OnDown(e); }
    }

    /// <summary>
    /// Factory helpers. Every node is anchored to the parent's top-left corner with a top-left
    /// pivot, so (x, y, w, h) are Godot-style coordinates: origin top-left, Y down.
    /// </summary>
    public static class UIKit
    {
        static Font _font;

        public static Font DefaultFont
        {
            get
            {
                if (_font == null) _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                return _font;
            }
        }

        // --- Nodes ---

        public static RectTransform Node(string name, Transform parent, float x, float y, float w, float h)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            Place(rt, x, y, w, h);
            return rt;
        }

        public static void Place(RectTransform rt, float x, float y, float w, float h)
        {
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.anchoredPosition = new Vector2(x, -y);
            rt.sizeDelta = new Vector2(w, h);
        }

        public static RectTransform Stretch(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;
            rt.pivot = new Vector2(0.5f, 0.5f);
            return rt;
        }

        // --- Shapes ---

        public static Image Solid(Transform parent, float x, float y, float w, float h, Color c, string name = "Solid")
        {
            var rt = Node(name, parent, x, y, w, h);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = false;
            return img;
        }

        public static Image Round(Transform parent, float x, float y, float w, float h, Color c, float radius, string name = "Round")
        {
            var rt = Node(name, parent, x, y, w, h);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = Sprites.RoundedRect(radius);
            img.type = Image.Type.Sliced;
            img.pixelsPerUnitMultiplier = Sprites.Scale;
            img.color = c;
            img.raycastTarget = false;
            return img;
        }

        public static Image Ring(Transform parent, float x, float y, float w, float h, Color c, float radius, float stroke, string name = "Ring")
        {
            var rt = Node(name, parent, x, y, w, h);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = Sprites.RoundedRing(radius, stroke);
            img.type = Image.Type.Sliced;
            img.pixelsPerUnitMultiplier = Sprites.Scale;
            img.color = c;
            img.raycastTarget = false;
            return img;
        }

        public static Image Circle(Transform parent, float cx, float cy, float r, Color c, string name = "Circle")
        {
            var rt = Node(name, parent, cx - r, cy - r, r * 2f, r * 2f);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = Sprites.Circle;
            img.color = c;
            img.raycastTarget = false;
            return img;
        }

        /// <summary>Soft drop shadow: a few translucent rounded rects growing outward.</summary>
        public static void Shadow(Transform parent, float x, float y, float w, float h, float radius, float size, float alpha, float offsetY)
        {
            const int layers = 4;
            for (int i = layers; i >= 1; i--)
            {
                float g = size * i / layers;
                Round(parent, x - g, y - g + offsetY, w + g * 2f, h + g * 2f,
                    new Color(0f, 0f, 0f, alpha / layers * 0.7f), radius + g, "Shadow");
            }
        }

        public struct PanelParts
        {
            public RectTransform Root;
            public Image Border, Fill;
        }

        /// <summary>Filled rounded panel with a 1px-style border (two stacked rounded rects).</summary>
        public static PanelParts Panel(Transform parent, float x, float y, float w, float h,
            Color fill, Color border, float radius, float borderW = 1f, string name = "Panel")
        {
            var root = Node(name, parent, x, y, w, h);
            var b = Round(root, 0, 0, w, h, border, radius, "Border");
            var f = Round(root, borderW, borderW, w - borderW * 2f, h - borderW * 2f, fill, Mathf.Max(0f, radius - borderW), "Fill");
            return new PanelParts { Root = root, Border = b, Fill = f };
        }

        /// <summary>Modal card: cream panel with wood border and a soft shadow (Godot _card_style).</summary>
        public static RectTransform Card(Transform parent, float x, float y, float w, float h)
        {
            var root = Node("Card", parent, x, y, w, h);
            Shadow(root, 0, 0, w, h, 16f, 18f, 0.5f, 6f);
            var p = Panel(root, 0, 0, w, h, Palette.Panel, Palette.PanelBorderHi, 16f);
            // Card swallows taps so nothing underneath reacts.
            p.Border.raycastTarget = true;
            return root;
        }

        // --- Text ---

        public static Text Label(Transform parent, string text, int size, Color color, float x, float y, float w, float h,
            TextAnchor anchor = TextAnchor.UpperCenter, string name = "Label")
        {
            var rt = Node(name, parent, x, y, w, h);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = DefaultFont;
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = anchor;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            return t;
        }

        /// <summary>Godot draw_string places text by BASELINE; this offsets a top-anchored label to match.</summary>
        public static float TopForBaseline(float baselineY, int fontSize) { return baselineY - fontSize * 0.92f; }

        public static float TextWidth(Text t) { return t.preferredWidth; }

        // --- Icons ---

        public static VectorGraphic Icon(Transform parent, string icon, float x, float y, float size, Color tint)
        {
            var rt = Node("Icon_" + icon, parent, x, y, size, size);
            var g = rt.gameObject.AddComponent<VectorGraphic>();
            g.raycastTarget = false;
            g.color = tint;
            Icons.Draw(g, icon, new Vector2(size * 0.5f, size * 0.5f), size);
            g.Commit();
            return g;
        }

        // --- Buttons ---

        public static StyledButton Button(Transform parent, float x, float y, float w, float h,
            ButtonTheme theme, float radius, string text, int fontSize, Action onClick,
            TextAnchor anchor = TextAnchor.MiddleCenter, float textPadX = 0f,
            float shadowSize = 2f, float shadowAlpha = 0.30f, float shadowOffset = 1f)
        {
            var root = Node("Button", parent, x, y, w, h);
            Shadow(root, 0, 0, w, h, radius, shadowSize, shadowAlpha, shadowOffset);
            var p = Panel(root, 0, 0, w, h, theme.Normal.Fill, theme.Normal.Border, radius);
            p.Border.raycastTarget = true; // border image is the hit area (covers the whole button)

            var btn = root.gameObject.AddComponent<StyledButton>();
            btn.Border = p.Border;
            btn.Fill = p.Fill;
            btn.Theme = theme;
            btn.OnClick = onClick;

            if (!string.IsNullOrEmpty(text))
            {
                btn.Label = Label(root, text, fontSize, theme.Normal.Text, textPadX, 0, w - textPadX * 2f, h, anchor, "Text");
            }
            btn.Refresh();
            return btn;
        }

        /// <summary>Square icon-only button (back / settings).</summary>
        public static StyledButton IconButton(Transform parent, string icon, float x, float y, float size, Action onClick)
        {
            var b = Button(parent, x, y, size, size, ButtonTheme.Secondary(), 24f, "", 14, onClick);
            var g = Icon(b.transform, icon, 0, 0, size, Palette.Text);
            g.name = "IconGlyph";
            return b;
        }

        /// <summary>Button whose (icon + label) group is centred as one unit (Undo / Hint / Play …).</summary>
        public static StyledButton IconTextButton(Transform parent, string icon, string text, float x, float y,
            float w, float h, ButtonTheme theme, int fontSize, int iconSize, float gap, Action onClick, float radius = 24f)
        {
            var b = Button(parent, x, y, w, h, theme, radius, "", fontSize, onClick);
            var label = Label(b.transform, text, fontSize, theme.Normal.Text, 0, 0, w, h, TextAnchor.MiddleLeft, "Text");
            b.Label = label;
            float textW = TextWidth(label);
            float groupW = iconSize + gap + textW;
            float groupX = Mathf.Max(8f, (w - groupW) * 0.5f);
            var ic = Icon(b.transform, icon, groupX, (h - iconSize) * 0.5f, iconSize, theme.Normal.Text);
            label.rectTransform.anchoredPosition = new Vector2(groupX + iconSize + gap, 0f);
            label.rectTransform.sizeDelta = new Vector2(textW + 4f, h);
            b.IconTint = ic;
            b.Refresh();
            return b;
        }
    }
}
