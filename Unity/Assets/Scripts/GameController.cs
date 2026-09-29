using System;
using System.Collections;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>
    /// App root: builds the canvas, owns progression + audio, routes between the menu screens
    /// and the game, and reacts to win / stuck. Port of the navigation half of Main.gd.
    /// </summary>
    public sealed class GameController : MonoBehaviour
    {
        /// <summary>Canvas height in units; width follows the screen aspect (Godot's "keep_height").</summary>
        public const float RefHeight = 854f;
        const float FadeIn = 0.16f, FadeOut = 0.20f;

        public static GameController Instance { get; private set; }

        public Progression Progress { get; private set; }
        public AudioManager Audio { get; private set; }

        RectTransform _screens, _gameRoot;
        Image _fade;
        BoardView _board;
        HudView _hud;
        GameObject _current;
        Coroutine _fadeRoutine;

        enum Screen_ { Menu, Packs, Levels, Settings, Game }
        Screen_ _screen = Screen_.Menu;
        int _levelsPack;

        public Vector2 Viewport
        {
            get { return new Vector2(RefHeight * UnityEngine.Screen.width / Mathf.Max(1, UnityEngine.Screen.height), RefHeight); }
        }

        public GameState State { get { return _board != null ? _board.State : null; } }

        public string CurrentLevelName
        {
            get
            {
                var info = LevelGenerator.GetPackInfo(_board.LevelIndex);
                return info.Name + " " + (info.LevelInPack + 1);
            }
        }

        public bool Colorblind { get { return Progress.Colorblind; } }
        public bool Muted { get { return Progress.Muted; } }
        public bool HapticsEnabled { get { return Progress.Haptics; } }

        // ------------------------------------------------------------------ startup

        void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;

            Application.targetFrameRate = 60;
            UnityEngine.Screen.orientation = ScreenOrientation.Portrait;

            Progress = new Progression();
            Audio = gameObject.AddComponent<AudioManager>();
            Audio.Muted = Progress.Muted;
            Audio.HapticsEnabled = Progress.Haptics;

            EnsureCamera();
            EnsureEventSystem();
            BuildCanvas();

            _board = BoardView.Create(this, _gameRoot);
            _hud = HudView.Create(this, _gameRoot);
            _gameRoot.gameObject.SetActive(false);

            ApplyMainMenu(); // first launch: no fade
        }

        static void EnsureCamera()
        {
            if (Camera.allCamerasCount > 0) return;
            var go = new GameObject("Camera");
            var cam = go.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Palette.BgMid;
            cam.orthographic = true;
            cam.cullingMask = 0;
            go.AddComponent<AudioListener>();
        }

        static void EnsureEventSystem()
        {
            if (EventSystem.current != null) return;
            var go = new GameObject("EventSystem", typeof(EventSystem));
#if ENABLE_LEGACY_INPUT_MANAGER
            go.AddComponent<StandaloneInputModule>();
#else
            // New Input System only: its UI module lives in the optional package, so add it by name.
            var t = Type.GetType("UnityEngine.InputSystem.UI.InputSystemUIInputModule, Unity.InputSystem");
            if (t != null)
            {
                var module = go.AddComponent(t);
                var assign = t.GetMethod("AssignDefaultActions");
                if (assign != null) assign.Invoke(module, null);
            }
            else Debug.LogError("HueHaven: no UI input module available. Enable 'Input Manager (Old)' or 'Both' in Player > Active Input Handling.");
#endif
        }

        void BuildCanvas()
        {
            var go = new GameObject("Canvas", typeof(RectTransform));
            go.transform.SetParent(transform, false);
            var canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = go.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(480f, RefHeight);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 1f; // keep height fixed
            go.AddComponent<GraphicRaycaster>();

            _screens = UIKit.Stretch("Screens", go.transform);
            _gameRoot = UIKit.Stretch("Game", go.transform);

            var fade = UIKit.Stretch("Fade", go.transform);
            _fade = fade.gameObject.AddComponent<Image>();
            _fade.color = new Color(0, 0, 0, 0);
            _fade.raycastTarget = false;
        }

        // ------------------------------------------------------------------ navigation

        /// <summary>Fade through black around a screen swap; input is blocked while fading.</summary>
        void Transition(Action apply)
        {
            if (_fadeRoutine != null) StopCoroutine(_fadeRoutine);
            _fadeRoutine = StartCoroutine(FadeRoutine(apply));
        }

        IEnumerator FadeRoutine(Action apply)
        {
            _fade.raycastTarget = true;
            for (float t = 0f; t < FadeIn; t += Time.unscaledDeltaTime)
            {
                SetFade(t / FadeIn);
                yield return null;
            }
            SetFade(1f);
            apply();
            for (float t = 0f; t < FadeOut; t += Time.unscaledDeltaTime)
            {
                SetFade(1f - t / FadeOut);
                yield return null;
            }
            SetFade(0f);
            _fade.raycastTarget = false;
            _fadeRoutine = null;
        }

        void SetFade(float a) { _fade.color = new Color(0, 0, 0, a); }

        void ClearScreen()
        {
            if (_current != null) Destroy(_current);
            _current = null;
        }

        void ShowMenuScreen(Screen_ s, Func<GameObject> build)
        {
            _screen = s;
            _hud.HideAll();
            _gameRoot.gameObject.SetActive(false);
            ClearScreen();
            _current = build();
        }

        public void ShowMainMenu() { Transition(ApplyMainMenu); }
        void ApplyMainMenu() { ShowMenuScreen(Screen_.Menu, () => MainMenuScreen.Build(this, _screens)); }

        public void ShowPackSelect() { Transition(() => ShowMenuScreen(Screen_.Packs, () => PackSelectScreen.Build(this, _screens))); }

        public void ShowLevelSelectForPack(int packIdx)
        {
            Transition(() =>
            {
                _levelsPack = packIdx;
                ShowMenuScreen(Screen_.Levels, () => LevelSelectScreen.Build(this, _screens, packIdx));
            });
        }

        public void ShowSettings() { Transition(() => ShowMenuScreen(Screen_.Settings, () => SettingsScreen.Build(this, _screens))); }

        public void StartLevel(int idx)
        {
            Transition(() =>
            {
                _screen = Screen_.Game;
                ClearScreen();
                _gameRoot.gameObject.SetActive(true);
                _hud.HideAll();
                _board.LoadLevel(idx);
            });
        }

        /// <summary>Back out of a level to that pack's level grid.</summary>
        public void BackToMenu() { ShowLevelSelectForPack(_board.PackIndex); }

        public void NextLevel()
        {
            int next = _board.LevelIndex + 1;
            if (next < LevelGenerator.TotalLevels) _board.LoadLevel(next);
            else ShowPackSelect();
        }

        public void RestartLevel()
        {
            _board.LoadLevel(_board.LevelIndex);
            _hud.HideStuck();
        }

        void Update()
        {
            if (BackPressed()) HandleBack();
        }

        static bool BackPressed()
        {
#if ENABLE_LEGACY_INPUT_MANAGER
            return Input.GetKeyDown(KeyCode.Escape); // Android back button / desktop Esc
#else
            return false;
#endif
        }

        void HandleBack()
        {
            switch (_screen)
            {
                case Screen_.Game: BackToMenu(); break;
                case Screen_.Levels: ShowPackSelect(); break;
                case Screen_.Packs:
                case Screen_.Settings: ShowMainMenu(); break;
                default: Application.Quit(); break;
            }
        }

        // ------------------------------------------------------------------ gameplay hooks

        public void UndoMove() { _board.Undo(); }
        public void ShowHint() { _board.ShowHint(); }
        public void HideStuck() { _hud.HideStuck(); }

        public void OnLevelWon()
        {
            int idx = _board.LevelIndex;
            int stars = _board.State.GetStarRating();
            Progress.SetStars(idx, stars);
            if (idx + 1 < LevelGenerator.TotalLevels) Progress.UnlockLevel(idx + 1);

            Audio.Play("win");
            Vector2 vp = Viewport;
            _board.SpawnConfetti(vp.x * 0.5f, vp.y * 0.4f, 60);
            _hud.ShowWin(stars, LevelGenerator.GetPackInfo(idx));
        }

        public void OnStuck()
        {
            Audio.Play("stuck");
            _hud.ShowStuck();
        }

        // ------------------------------------------------------------------ settings

        public bool ToggleColorblind()
        {
            Progress.Colorblind = !Progress.Colorblind;
            return Progress.Colorblind;
        }

        public bool ToggleMute()
        {
            Progress.Muted = !Progress.Muted;
            Audio.Muted = Progress.Muted;
            return Progress.Muted;
        }

        public bool ToggleHaptics()
        {
            Progress.Haptics = !Progress.Haptics;
            Audio.HapticsEnabled = Progress.Haptics;
            if (Progress.Haptics) Haptics.Vibrate(30); // quick test buzz so the player feels what they enabled
            return Progress.Haptics;
        }
    }

    /// <summary>Starts the game in any scene — no scene wiring needed.</summary>
    public static class Bootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Init()
        {
            if (GameController.Instance != null) return;
            var go = new GameObject("HueHaven");
            go.AddComponent<GameController>();
        }
    }
}
