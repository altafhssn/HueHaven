using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>
    /// The playing field: glass tubes, pearls, selection / hint / sparkle effects, move animation,
    /// confetti. Port of the gameplay half of Main.gd (layout maths, timings and formulas unchanged).
    /// </summary>
    public sealed class BoardView : MonoBehaviour
    {
        // --- One pearl on screen ---
        sealed class PearlView
        {
            public RectTransform Rt;
            RawImage _tex;
            Image _fallback;
            VectorGraphic _marker;
            Text _count;
            Ball _bound;
            int _boundMeta = int.MinValue;
            bool _boundCb;
            bool _hasBound;
            float _d;

            public PearlView(Transform parent, float diameter, float ballRadius)
            {
                _d = diameter;
                Rt = UIKit.Node("Pearl", parent, 0, 0, diameter, diameter);
                Rt.pivot = new Vector2(0.5f, 0.5f);
                _tex = UIKit.Node("Tex", Rt, 0, 0, diameter, diameter).gameObject.AddComponent<RawImage>();
                _tex.raycastTarget = false;
                _fallback = UIKit.Circle(Rt, diameter * 0.5f, diameter * 0.5f, diameter * 0.5f, Color.white, "Fallback");
                _marker = UIKit.Node("Marker", Rt, 0, 0, diameter, diameter).gameObject.AddComponent<VectorGraphic>();
                _marker.raycastTarget = false;
                _count = UIKit.Label(Rt, "", Mathf.Max(10, Mathf.RoundToInt(ballRadius * 0.75f)), Color.white,
                    0, 0, diameter, diameter, TextAnchor.MiddleCenter, "Count");
                var ol = _count.gameObject.AddComponent<Outline>();
                ol.effectColor = new Color(0, 0, 0, 0.75f);
                ol.effectDistance = new Vector2(1.5f, -1.5f);
                _markerR = ballRadius * 0.45f;
                SetActive(false);
            }

            float _markerR;

            public void SetActive(bool on) { if (Rt.gameObject.activeSelf != on) Rt.gameObject.SetActive(on); }

            /// <summary>Position by centre, in the parent's top-left/Y-down space.</summary>
            public void SetCenter(float cx, float cy) { Rt.anchoredPosition = new Vector2(cx, -cy); }

            public void Bind(Ball b, bool colorblind)
            {
                if (_hasBound && ReferenceEquals(_bound, b) && _boundMeta == b.Meta && _boundCb == colorblind) return;
                _hasBound = true; _bound = b; _boundMeta = b.Meta; _boundCb = colorblind;

                Texture2D tex = null;
                if (b.IsSpecial) tex = GameAssets.Special(b.Kind);
                if (tex == null && b.Color >= 0) tex = GameAssets.Pearl(b.Color);

                if (tex != null)
                {
                    _tex.enabled = true; _tex.texture = tex; _fallback.enabled = false;
                }
                else
                {
                    _tex.enabled = false; _fallback.enabled = true;
                    _fallback.color = FallbackColor(b);
                }

                _marker.Clear();
                if (colorblind && b.Color >= 0 && b.Kind != BallKind.Rainbow)
                    DrawMarker(_marker, new Vector2(_d * 0.5f, _d * 0.5f), b.Color, _markerR);
                _marker.Commit();

                bool bomb = b.Kind == BallKind.Bomb;
                _count.enabled = bomb;
                _count.GetComponent<Outline>().enabled = bomb;
                if (bomb) _count.text = b.Meta.ToString();
            }

            static Color FallbackColor(Ball b)
            {
                if (b.Kind == BallKind.Rainbow) return Color.HSVToRGB(Mathf.Repeat(Time.unscaledTime * 0.5f, 1f), 0.7f, 0.95f);
                if (b.Kind == BallKind.Stone) return Palette.Hex("#7A7060");
                if (b.Color >= 0) return Palette.FallbackBall[b.Color % Palette.FallbackBall.Length];
                return Palette.Hex("#888888");
            }
        }

        // --- One glass tube on screen ---
        sealed class TubeView
        {
            public RectTransform Root;
            public Image[] Glow;
            public Image[] Slots;
            public Image Sparkle, Hint;
            public PearlView[] Pearls;
        }

        sealed class Particle
        {
            public Image Img;
            public Vector2 Pos, Vel;
            public float Life, Size;
        }

        GameController _g;
        Vector2 _vp;
        RectTransform _root, _stageLayer, _tubeLayer, _fxLayer, _confettiLayer;

        GameState _state;
        TubeView[] _tubes = new TubeView[0];
        PearlView _flying;

        // Layout (recomputed per level).
        float _tubeW, _tubeH, _ballR, _tubeGap;
        Vector2 _grid;

        // Interaction / animation state.
        int _selected = -1;
        bool _moveAnimating;
        int _animFrom = -1, _animTo = -1;
        float _animProgress;
        Ball _animBall;
        float[] _shake = new float[0];
        readonly HashSet<int> _sparkle = new HashSet<int>();
        int _hintFrom = -1, _hintTo = -1;
        float _hintTimer;
        bool _winShown, _stuck;
        readonly List<Particle> _confetti = new List<Particle>();

        public int LevelIndex { get; private set; }
        public int PackIndex { get { return LevelGenerator.PackIndexFor(LevelIndex); } }
        public GameState State { get { return _state; } }
        public bool IsAnimating { get { return _moveAnimating; } }

        public static BoardView Create(GameController g, Transform parent)
        {
            var rt = UIKit.Stretch("Board", parent);
            var board = rt.gameObject.AddComponent<BoardView>();
            board.Init(g, rt);
            return board;
        }

        void Init(GameController g, RectTransform root)
        {
            _g = g;
            _root = root;
            _vp = g.Viewport;

            // Cafe background — a single full-screen blit.
            var bgTex = GameAssets.CafeBackground;
            if (bgTex != null)
            {
                var bg = UIKit.Stretch("CafeArt", root).gameObject.AddComponent<RawImage>();
                bg.texture = bgTex;
                bg.raycastTarget = false;
            }
            else CafeBackground.Create(root, _vp, Theme.Underwater);

            // Transparent full-screen hit area receives taps; the HUD sits above it.
            var hit = root.gameObject.AddComponent<Image>();
            hit.color = new Color(0, 0, 0, 0);
            hit.raycastTarget = true;
            root.gameObject.AddComponent<TapArea>().OnDown = OnTap;

            _stageLayer = UIKit.Stretch("Stage", root);
            _tubeLayer = UIKit.Stretch("Tubes", root);
            _fxLayer = UIKit.Stretch("Fx", root);
            _confettiLayer = UIKit.Stretch("Confetti", root);
        }

        // ---------------------------------------------------------------- level lifecycle

        public void LoadLevel(int idx)
        {
            LevelIndex = idx;
            _state = new GameState(LevelGenerator.Generate(idx));

            ClearChildren(_stageLayer);
            ClearChildren(_tubeLayer);
            ClearChildren(_fxLayer);
            ClearChildren(_confettiLayer);
            _confetti.Clear();

            _selected = -1;
            _moveAnimating = false;
            _animBall = null;
            _winShown = false;
            _stuck = false;
            _hintFrom = _hintTo = -1;
            _hintTimer = 0f;
            _sparkle.Clear();

            CalcLayout(_state.Level);
            BuildStage();
            BuildTubes(_state.Level);
            _flying = new PearlView(_fxLayer, _ballR * 1.85f, _ballR);
            _shake = new float[_state.Tubes.Count];
            RefreshVisuals(Time.unscaledTime);
        }

        static void ClearChildren(Transform t)
        {
            for (int i = t.childCount - 1; i >= 0; i--) Destroy(t.GetChild(i).gameObject);
        }

        // Port of Main._calc_grid_offset(): fit N tubes between the header and the action bar.
        void CalcLayout(Level level)
        {
            int n = level.Contents.Count;
            int capacity = level.Capacity;

            const float topChrome = 96f, bottomChrome = 104f, sideMargin = 16f;
            float zoneTop = topChrome;
            float zoneH = _vp.y - topChrome - bottomChrome;

            float gap = 14f;
            float availW = _vp.x - sideMargin * 2f;
            float maxTubeWByWidth = (availW - gap * (n - 1)) / n;
            float maxTubeH = zoneH * 0.88f;
            float maxBallRByHeight = (maxTubeH - 16f) / (capacity * 2f + (capacity - 1) * 0.1f);

            _tubeW = Mathf.Clamp(maxTubeWByWidth, 32f, 92f);
            if (maxTubeWByWidth < 32f)
            {
                gap = Mathf.Max(4f, (availW - 32f * n) / Mathf.Max(1, n - 1));
                _tubeW = 32f;
            }

            float ballRByWidth = _tubeW * 0.44f;
            _ballR = Mathf.Clamp(Mathf.Min(ballRByWidth, maxBallRByHeight), 12f, 42f);
            _tubeH = (_ballR * 2f + 4f) * capacity + 18f;
            _tubeGap = gap;

            float totalW = n * (_tubeW + gap) - gap;
            _grid = new Vector2((_vp.x - totalW) / 2f, zoneTop + (zoneH - _tubeH) / 2f);
        }

        void BuildStage()
        {
            // Soft walnut strip behind the row of tubes.
            const float pad = 20f;
            UIKit.Solid(_stageLayer, 0, _grid.y - pad, _vp.x, _tubeH + pad * 2f, new Color(0.20f, 0.13f, 0.08f, 0.20f), "StageStrip");
        }

        void BuildTubes(Level level)
        {
            int n = level.Contents.Count;
            int cap = level.Capacity;
            _tubes = new TubeView[n];
            var strawTex = GameAssets.Straw(PackIndex);
            float pearlD = _ballR * 1.85f;

            for (int i = 0; i < n; i++)
            {
                var tv = new TubeView();
                tv.Root = UIKit.Node("Tube_" + i, _tubeLayer, 0, 0, _tubeW, _tubeH);

                // Selection glow, 4 growing rings behind the glass.
                tv.Glow = new Image[4];
                for (int k = 0; k < 4; k++)
                {
                    float grow = 4f + k * 4f;
                    var col = Palette.WithAlpha(Palette.Accent, 0.20f / (k + 1));
                    tv.Glow[k] = UIKit.Round(tv.Root, -grow, -grow, _tubeW + grow * 2f, _tubeH + grow * 2f, col, 18f + k * 4f, "Glow" + k);
                    tv.Glow[k].gameObject.SetActive(false);
                }

                BuildGlass(tv.Root);

                // Paper straw, poking above the rim and running nearly to the bottom.
                if (strawTex != null)
                {
                    float sw = _tubeW * 0.30f;
                    float poke = _tubeH * 0.32f;
                    float sh = _tubeH * 0.95f + poke;
                    var straw = UIKit.Node("Straw", tv.Root, _tubeW * 0.50f, -poke, sw, sh).gameObject.AddComponent<RawImage>();
                    straw.texture = strawTex;
                    straw.raycastTarget = false;
                }

                // Empty-slot markers.
                tv.Slots = new Image[cap];
                for (int j = 0; j < cap; j++)
                {
                    tv.Slots[j] = UIKit.Circle(tv.Root, _tubeW * 0.5f, SlotY(j), _ballR * 0.42f,
                        new Color(0.55f, 0.78f, 0.92f, 0.18f), "Slot" + j);
                    tv.Slots[j].gameObject.SetActive(false);
                }

                // Pearl pool.
                tv.Pearls = new PearlView[cap];
                for (int j = 0; j < cap; j++) tv.Pearls[j] = new PearlView(tv.Root, pearlD, _ballR);

                // Completion sparkle + hint rings.
                tv.Sparkle = UIKit.Ring(tv.Root, -3, -3, _tubeW + 6f, _tubeH + 6f, Palette.Success, 14f, 2f, "Sparkle");
                tv.Sparkle.gameObject.SetActive(false);
                tv.Hint = UIKit.Ring(tv.Root, -4, -4, _tubeW + 8f, _tubeH + 8f, Palette.Accent, 14f, 2.5f, "Hint");
                tv.Hint.gameObject.SetActive(false);

                _tubes[i] = tv;
            }
        }

        float SlotY(int j) { return _tubeH - (j + 1) * (_ballR * 2f + 2f); }

        // Procedural glass — cleaner than the texture, which had chroma-key fringing.
        void BuildGlass(Transform tube)
        {
            var g = UIKit.Node("Glass", tube, 0, 0, _tubeW, _tubeH).gameObject.AddComponent<VectorGraphic>();
            g.raycastTarget = false;
            float w = _tubeW, h = _tubeH;

            g.FillRoundedGradient(0, 0, w, h, 8f, new Color(0.96f, 0.92f, 0.85f, 0.22f), new Color(0.85f, 0.78f, 0.68f, 0.18f));

            float rimH = Mathf.Max(4f, h * 0.022f);
            g.FillRect(2, 0, w - 4, rimH, new Color(0.96f, 0.88f, 0.70f, 1f));                       // warm cream rim
            g.FillRect(2, rimH, w - 4, 2, new Color(0.20f, 0.10f, 0f, 0.55f));                       // inner rim shadow
            g.FillRect(2, rimH + 4, 3, h - rimH - 14, new Color(1, 1, 1, 0.65f));                    // left wall highlight
            g.FillRect(w - 5, rimH + 4, 3, h - rimH - 14, new Color(0.20f, 0.10f, 0f, 0.45f));       // right wall shadow
            g.FillRect(2, h - 8, w - 4, 5, new Color(0.20f, 0.10f, 0f, 0.65f));                      // base refraction
            g.RectOutline(0, 0, w, h, new Color(0.30f, 0.20f, 0.12f, 0.45f), 1.5f);                  // walnut border
            g.Commit();
        }

        // ---------------------------------------------------------------- input

        void OnTap(PointerEventData e)
        {
            if (_state == null || _moveAnimating || _state.IsLevelWon()) return;

            Vector2 local;
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(_root, e.position, e.pressEventCamera, out local)) return;
            Rect r = _root.rect;
            float px = local.x - r.xMin;
            float py = r.yMax - local.y; // top-left origin, Y down

            for (int i = 0; i < _tubes.Length; i++)
            {
                float tx = _grid.x + i * (_tubeW + _tubeGap);
                if (px >= tx && px <= tx + _tubeW && py >= _grid.y && py <= _grid.y + _tubeH)
                {
                    OnTubeTapped(i);
                    return;
                }
            }
        }

        void OnTubeTapped(int idx)
        {
            // Any interaction clears the active hint.
            if (_hintTimer > 0f) { _hintTimer = 0f; _hintFrom = _hintTo = -1; }

            if (_selected < 0)
            {
                var contents = _state.Tubes[idx];
                if (contents.Count > 0 && !_state.IsTubeComplete(idx))
                {
                    if (contents[contents.Count - 1].IsStone) // stones can't be picked up
                    {
                        _shake[idx] = 0.3f;
                        _g.Audio.Play("invalid");
                        return;
                    }
                    _selected = idx;
                    _g.Audio.Play("select");
                }
            }
            else if (idx == _selected)
            {
                _selected = -1;
                _g.Audio.Play("deselect");
            }
            else if (_state.CanMove(_selected, idx))
            {
                StartMove(_selected, idx);
                _selected = -1;
            }
            else
            {
                _shake[idx] = 0.3f;
                _g.Audio.Play("invalid");
            }
        }

        void StartMove(int from, int to)
        {
            _moveAnimating = true;
            _animFrom = from;
            _animTo = to;
            _animProgress = 0f;
            var src = _state.Tubes[from];
            _animBall = src[src.Count - 1];
            _g.Audio.Play("move");
        }

        // ---------------------------------------------------------------- per-frame

        void Update()
        {
            if (_state == null || !gameObject.activeInHierarchy) return;
            float dt = Time.unscaledDeltaTime;

            for (int i = 0; i < _shake.Length; i++)
                if (_shake[i] > 0f) _shake[i] = Mathf.Max(0f, _shake[i] - dt);

            if (_hintTimer > 0f)
            {
                _hintTimer -= dt;
                if (_hintTimer <= 0f) _hintFrom = _hintTo = -1;
            }

            if (_moveAnimating)
            {
                _animProgress += dt * 2f;
                if (_animProgress >= 1f) FinishMove();
            }

            UpdateConfetti(dt);
            RefreshVisuals(Time.unscaledTime);
        }

        void FinishMove()
        {
            _animProgress = 1f;
            _state.MoveBall(_animFrom, _animTo);
            _moveAnimating = false;
            _animBall = null;

            // Drain queued special effects.
            foreach (var fx in _state.TakeEffects())
            {
                _g.Audio.Play(AudioManager.EventName(fx.Type));
                if (fx.Type == EffectType.BombExplode) SpawnExplosion(fx.Tube);
            }

            if (_state.IsTubeComplete(_animTo))
            {
                _sparkle.Add(_animTo);
                _g.Audio.Play("complete_tube");
            }

            if (_state.IsLevelWon() && !_winShown)
            {
                _winShown = true;
                _g.OnLevelWon();
            }
            else if (!_state.HasAnyMove() && !_stuck)
            {
                _stuck = true;
                _g.OnStuck();
            }
        }

        void RefreshVisuals(float t)
        {
            bool cb = _g.Colorblind;
            int cap = _state.Capacity;
            float slotPitch = _ballR * 2f + 2f;

            for (int i = 0; i < _tubes.Length; i++)
            {
                var tv = _tubes[i];
                float shakeX = 0f;
                if (_shake[i] > 0f) shakeX = Mathf.Sin(_shake[i] * 60f) * 8f * Mathf.Min(_shake[i] / 0.3f, 1f);
                UIKit.Place(tv.Root, _grid.x + i * (_tubeW + _tubeGap) + shakeX, _grid.y, _tubeW, _tubeH);

                bool selected = _selected == i;
                foreach (var glow in tv.Glow) if (glow.gameObject.activeSelf != selected) glow.gameObject.SetActive(selected);

                var contents = _state.Tubes[i];
                int n = contents.Count;
                // The in-flight pearl is drawn by _flying, not by its source tube.
                int drawCount = (_moveAnimating && i == _animFrom) ? n - 1 : n;

                for (int j = 0; j < cap; j++)
                {
                    var pv = tv.Pearls[j];
                    if (j < drawCount)
                    {
                        float lift = (selected && j == n - 1) ? -20f - Mathf.Sin(t * 5f) * 4f : 0f;
                        pv.Bind(contents[j], cb);
                        pv.SetCenter(_tubeW * 0.5f, SlotY(j) + lift);
                        pv.SetActive(true);
                    }
                    else pv.SetActive(false);

                    bool showSlot = j >= drawCount;
                    if (tv.Slots[j].gameObject.activeSelf != showSlot) tv.Slots[j].gameObject.SetActive(showSlot);
                }

                bool sparkle = _sparkle.Contains(i);
                if (tv.Sparkle.gameObject.activeSelf != sparkle) tv.Sparkle.gameObject.SetActive(sparkle);
                if (sparkle) tv.Sparkle.color = Palette.WithAlpha(Palette.Success, Mathf.Abs(Mathf.Sin(t * 4f)) * 0.5f);

                bool hint = _hintTimer > 0f && (i == _hintFrom || i == _hintTo);
                if (tv.Hint.gameObject.activeSelf != hint) tv.Hint.gameObject.SetActive(hint);
                if (hint)
                {
                    var hc = i == _hintFrom ? Palette.Accent : Palette.Success;
                    tv.Hint.color = Palette.WithAlpha(hc, Mathf.Abs(Mathf.Sin(t * 8f)) * 0.8f);
                }
            }

            // Pearl in flight: arcs from the source tube to the destination slot.
            if (_moveAnimating && _animBall != null)
            {
                float fromX = _grid.x + _animFrom * (_tubeW + _tubeGap) + _tubeW * 0.5f;
                float toX = _grid.x + _animTo * (_tubeW + _tubeGap) + _tubeW * 0.5f;
                float fromY = _grid.y + _tubeH - (_state.Tubes[_animFrom].Count + 1) * slotPitch;
                float toY = _grid.y + _tubeH - (_state.Tubes[_animTo].Count + 1) * slotPitch;

                float px = Mathf.Lerp(fromX, toX, _animProgress);
                float py = Mathf.Lerp(fromY - 30f, toY, _animProgress);
                float arc = Mathf.Sin(_animProgress * Mathf.PI) * -60f;
                _flying.Bind(_animBall, cb);
                _flying.SetCenter(px, py + arc);
                _flying.SetActive(true);
            }
            else _flying.SetActive(false);
        }

        // ---------------------------------------------------------------- effects

        public void SpawnConfetti(float x, float y, int count)
        {
            for (int i = 0; i < count; i++)
            {
                float angle = Random.Range(-Mathf.PI, 0f); // upward arc
                float speed = Random.Range(150f, 380f);
                float size = Random.Range(3f, 6f);
                var col = Palette.ConfettiColors[Random.Range(0, Palette.ConfettiColors.Length)];
                var p = new Particle
                {
                    Pos = new Vector2(x + Random.Range(-20f, 20f), y),
                    Vel = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * speed,
                    Life = Random.Range(1.0f, 1.8f),
                    Size = size,
                    Img = UIKit.Circle(_confettiLayer, 0, 0, size, col, "Confetti"),
                };
                _confetti.Add(p);
            }
        }

        void SpawnExplosion(int tube)
        {
            _shake[tube] = 0.5f;
            float x = _grid.x + tube * (_tubeW + _tubeGap) + _tubeW * 0.5f;
            float y = _grid.y + _tubeH * 0.5f;
            SpawnConfetti(x, y, 20);
        }

        void UpdateConfetti(float dt)
        {
            for (int i = _confetti.Count - 1; i >= 0; i--)
            {
                var p = _confetti[i];
                p.Vel.y += 220f * dt;
                p.Pos += p.Vel * dt;
                p.Life -= dt;
                if (p.Life <= 0f || p.Pos.y >= _vp.y + 40f)
                {
                    Destroy(p.Img.gameObject);
                    _confetti.RemoveAt(i);
                    continue;
                }
                UIKit.Place(p.Img.rectTransform, p.Pos.x - p.Size, p.Pos.y - p.Size, p.Size * 2f, p.Size * 2f);
                var c = p.Img.color;
                c.a = Mathf.Clamp01(p.Life / 1.5f);
                p.Img.color = c;
            }
        }

        // ---------------------------------------------------------------- commands

        public void Undo()
        {
            if (_moveAnimating || _state == null) return;
            if (_state.Undo())
            {
                _g.Audio.Play("undo");
                _stuck = false;
                _sparkle.RemoveWhere(i => !_state.IsTubeComplete(i));
                _g.HideStuck();
            }
        }

        public void ShowHint()
        {
            if (_state == null || _moveAnimating || _state.IsLevelWon()) return;
            var hint = _state.FindHint();
            if (hint.from >= 0)
            {
                _hintFrom = hint.from;
                _hintTo = hint.to;
                _hintTimer = 1.8f;
            }
        }

        // ---------------------------------------------------------------- colour-blind shape markers

        // Dark marker that reads on both light and saturated pearls. Port of _draw_colorblind_marker.
        static void DrawMarker(VectorGraphic g, Vector2 c, int colorIdx, float r)
        {
            var col = new Color(0.1f, 0.08f, 0.05f, 0.7f);
            switch (colorIdx % 6)
            {
                case 0: // circle
                    g.CircleOutline(c, r, col, 2f, 12);
                    break;
                case 1: // triangle
                    g.Polyline(new[] { c + new Vector2(0, -r), c + new Vector2(r * 0.9f, r * 0.6f), c + new Vector2(-r * 0.9f, r * 0.6f) }, col, 2f, true);
                    break;
                case 2: // square
                {
                    float s = r * 0.8f;
                    g.Polyline(new[] { c + new Vector2(-s, -s), c + new Vector2(s, -s), c + new Vector2(s, s), c + new Vector2(-s, s) }, col, 2f, true);
                    break;
                }
                case 3: // diamond
                    g.Polyline(new[] { c + new Vector2(0, -r), c + new Vector2(r, 0), c + new Vector2(0, r), c + new Vector2(-r, 0) }, col, 2f, true);
                    break;
                case 4: // cross
                    g.Line(c + new Vector2(0, -r), c + new Vector2(0, r), col, 2f);
                    g.Line(c + new Vector2(-r, 0), c + new Vector2(r, 0), col, 2f);
                    break;
                default: // double ring
                    g.CircleOutline(c, r, col, 2f, 16);
                    g.CircleOutline(c, r * 0.5f, col, 1.5f, 10);
                    break;
            }
        }
    }
}
