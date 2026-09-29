using UnityEngine;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>
    /// In-game chrome: back / settings buttons, level name, move counter, Undo / Hint / Restart bar,
    /// and the win, stuck and settings overlays. Port of HUD.gd.
    /// </summary>
    public sealed class HudView : MonoBehaviour
    {
        GameController _g;
        Vector2 _vp;

        Text _levelName, _moves;
        string _lastMoves, _lastName;

        GameObject _winOverlay, _stuckOverlay, _settingsOverlay;
        Text _winInfo;
        VectorGraphic[] _winStars;
        Text _cbState, _soundState;

        public static HudView Create(GameController g, Transform parent)
        {
            var rt = UIKit.Stretch("Hud", parent);
            var hud = rt.gameObject.AddComponent<HudView>();
            hud.Build(g);
            return hud;
        }

        void Build(GameController g)
        {
            _g = g;
            _vp = g.Viewport;
            var root = (RectTransform)transform;

            UIKit.IconButton(root, "back", 14, 14, 38, OnMenu).name = "MenuButton";
            UIKit.IconButton(root, "settings", _vp.x - 52f, 14, 38, OpenSettings).name = "SettingsButton";

            // Level name — bold, uppercase, faint glow.
            _levelName = UIKit.Label(root, "", 22, Palette.Text, 0, 18, _vp.x, 28, TextAnchor.UpperCenter, "LevelName");
            var glow = _levelName.gameObject.AddComponent<Outline>();
            glow.effectColor = new Color(0.5f, 0.78f, 0.92f, 0.35f);
            glow.effectDistance = new Vector2(2f, 2f);

            // Moves chip.
            float chipX = (_vp.x - 120f) / 2f;
            UIKit.Panel(root, chipX, 50, 120, 26, Palette.Panel, Palette.PanelBorder, 13f, 1f, "MovesChip");
            _moves = UIKit.Label(root, "0 moves", 12, Palette.TextMuted, chipX, 50, 120, 26, TextAnchor.MiddleCenter, "MovesLabel");

            // Bottom action bar.
            const float barH = 96f;
            UIKit.Solid(root, 0, _vp.y - barH, _vp.x, barH, Palette.WithAlpha(Palette.Panel, 0.85f), "ActionBar");
            UIKit.Solid(root, 0, _vp.y - barH, _vp.x, 1, Palette.PanelBorder, "ActionBarEdge");

            const float btnW = 116f, btnH = 50f, gap = 14f;
            float total = btnW * 3 + gap * 2;
            float startX = (_vp.x - total) / 2f;
            float btnY = _vp.y - barH + (barH - btnH) / 2f;
            UIKit.IconTextButton(root, "undo", "Undo", startX, btnY, btnW, btnH, ButtonTheme.Secondary(), 15, 22, 8f, OnUndo).name = "UndoButton";
            UIKit.IconTextButton(root, "hint", "Hint", startX + btnW + gap, btnY, btnW, btnH, ButtonTheme.Primary(), 15, 22, 8f, OnHint).name = "HintButton";
            UIKit.IconTextButton(root, "restart", "Restart", startX + (btnW + gap) * 2f, btnY, btnW, btnH, ButtonTheme.Secondary(), 15, 22, 8f, OnRestart).name = "RestartButton";

            BuildWinOverlay(root);
            BuildStuckOverlay(root);
            BuildSettingsOverlay(root);
        }

        static GameObject MakeOverlay(Transform parent, string name, float dimAlpha, bool blocksInput)
        {
            var rt = UIKit.Stretch(name, parent);
            var dim = rt.gameObject.AddComponent<Image>();
            dim.color = new Color(0, 0, 0, dimAlpha);
            dim.raycastTarget = blocksInput;
            rt.gameObject.SetActive(false);
            return rt.gameObject;
        }

        void BuildWinOverlay(Transform root)
        {
            _winOverlay = MakeOverlay(root, "WinOverlay", 0.55f, true);
            const float cw = 320f, ch = 290f;
            var card = UIKit.Card(_winOverlay.transform, (_vp.x - cw) / 2f, (_vp.y - ch) / 2f, cw, ch);

            UIKit.Label(card, "Level Complete", 26, Palette.Text, 0, 28, cw, 32, TextAnchor.UpperCenter, "Title");

            _winStars = new VectorGraphic[3];
            const float starSz = 52f, starGap = 14f;
            float sx0 = (cw - (3f * starSz + 2f * starGap)) * 0.5f;
            for (int i = 0; i < 3; i++)
                _winStars[i] = UIKit.Icon(card, "star", sx0 + i * (starSz + starGap), 80f + (64f - starSz) * 0.5f, starSz, Palette.TextDim);

            _winInfo = UIKit.Label(card, "", 13, Palette.TextMuted, 0, 152, cw, 22, TextAnchor.UpperCenter, "Info");

            UIKit.IconTextButton(card, "next", "Next", 30, 200, cw - 60f, 44, ButtonTheme.Primary(), 16, 20, 8f, OnNext, 22f)
                .name = "NextButton";
            var menu = UIKit.Button(card, 30, 250, cw - 60f, 36, ButtonTheme.Secondary(), 18f, "Level Select", 14, OnMenu);
            menu.Theme.Normal.Text = Palette.TextMuted;
            menu.Theme.Hover.Text = Palette.TextMuted;
            menu.Theme.Pressed.Text = Palette.TextMuted;
            menu.Refresh();
            menu.name = "LevelSelectButton";
        }

        void BuildStuckOverlay(Transform root)
        {
            // Dim only — the tubes underneath stay tappable, as in the Godot version.
            _stuckOverlay = MakeOverlay(root, "StuckOverlay", 0.5f, false);
            const float cw = 300f, ch = 140f;
            var card = UIKit.Card(_stuckOverlay.transform, (_vp.x - cw) / 2f, _vp.y * 0.42f - 22f, cw, ch);
            UIKit.Label(card, "No moves left", 20, Palette.Danger, 0, 22, cw, 28, TextAnchor.UpperCenter, "Title");
            UIKit.IconTextButton(card, "undo", "Undo", 30, 72, 110, 44, ButtonTheme.Secondary(), 14, 18, 6f, OnUndo, 22f);
            UIKit.IconTextButton(card, "restart", "Restart", 160, 72, 110, 44, ButtonTheme.Secondary(), 14, 18, 6f, OnRestart, 22f);
        }

        void BuildSettingsOverlay(Transform root)
        {
            _settingsOverlay = MakeOverlay(root, "SettingsOverlay", 0.6f, true);
            const float cw = 320f, ch = 240f;
            var card = UIKit.Card(_settingsOverlay.transform, (_vp.x - cw) / 2f, (_vp.y - ch) / 2f, cw, ch);
            UIKit.Label(card, "Settings", 20, Palette.Text, 0, 12, cw, 28, TextAnchor.UpperCenter, "Title");
            SettingsScreen.MakeRow(card, "Colorblind shapes", 20, 50, 280, 44,
                () => { _g.ToggleColorblind(); RefreshSettings(); }, out _cbState);
            SettingsScreen.MakeRow(card, "Sound", 20, 102, 280, 44,
                () => { _g.ToggleMute(); RefreshSettings(); }, out _soundState);
            UIKit.Button(card, 80, 168, 160, 40, ButtonTheme.Secondary(), 22f, "Close", 14, CloseSettings);
        }

        // --- Per-frame labels ---

        void Update()
        {
            var state = _g.State;
            if (state == null) return;

            int par = state.Level.ParMoves;
            string moves = par > 0 ? state.MoveCount + " / " + par + " moves" : state.MoveCount + " moves";
            if (moves != _lastMoves) { _lastMoves = moves; _moves.text = moves; }

            string name = _g.CurrentLevelName.ToUpperInvariant();
            if (name != _lastName) { _lastName = name; _levelName.text = name; }
        }

        // --- Overlays ---

        public void ShowWin(int stars, PackInfo info)
        {
            if (_winOverlay.activeSelf) return;
            for (int i = 0; i < _winStars.Length; i++)
                _winStars[i].color = i < stars ? Palette.Star : Palette.TextDim;
            _winInfo.text = info.Name + " · Level " + (info.LevelInPack + 1);
            _winOverlay.SetActive(true);
        }

        public void ShowStuck() { _stuckOverlay.SetActive(true); }
        public void HideStuck() { _stuckOverlay.SetActive(false); }

        void HideWin() { _winOverlay.SetActive(false); }

        public void HideAll()
        {
            _winOverlay.SetActive(false);
            _stuckOverlay.SetActive(false);
            _settingsOverlay.SetActive(false);
        }

        void OpenSettings()
        {
            RefreshSettings();
            _settingsOverlay.SetActive(true);
        }

        void CloseSettings() { _settingsOverlay.SetActive(false); }

        void RefreshSettings()
        {
            SettingsScreen.SetState(_cbState, _g.Colorblind);
            SettingsScreen.SetState(_soundState, !_g.Muted);
        }

        // --- Button handlers ---

        void OnUndo() { _g.UndoMove(); }
        void OnHint() { _g.ShowHint(); }

        void OnRestart()
        {
            _g.RestartLevel();
            HideWin();
        }

        void OnNext()
        {
            HideWin();
            _g.NextLevel();
        }

        void OnMenu()
        {
            HideAll();
            _g.BackToMenu();
        }
    }
}
