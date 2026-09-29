using System.Collections.Generic;
using UnityEngine;

namespace HueHaven
{
    /// <summary>
    /// Sound-effect + haptics dispatcher. Clips are loaded from Resources/Audio by event name
    /// (drop in `<event>.wav` or `.ogg` to add / replace a sound). Port of scripts/Audio.gd.
    /// </summary>
    public sealed class AudioManager : MonoBehaviour
    {
        public static readonly string[] Events =
        {
            "select", "deselect", "move", "invalid", "complete_tube", "undo", "win",
            "stuck", "bomb_tick", "bomb_explode", "magnet_pull", "hourglass_use",
        };

        // Per-event haptic strength in milliseconds; 0 disables.
        static readonly Dictionary<string, int> HapticMs = new Dictionary<string, int>
        {
            { "select", 15 }, { "deselect", 0 }, { "move", 12 },
            { "invalid", 45 },       // noticeable thud on a bad move
            { "complete_tube", 25 }, { "undo", 10 },
            { "win", 120 },          // celebratory long buzz
            { "stuck", 60 }, { "bomb_tick", 0 }, { "bomb_explode", 90 },
            { "magnet_pull", 30 }, { "hourglass_use", 20 },
        };

        const int VoiceCount = 8;

        public bool Muted;
        public bool HapticsEnabled = true;

        readonly Dictionary<string, AudioClip> _clips = new Dictionary<string, AudioClip>();
        readonly List<AudioSource> _voices = new List<AudioSource>();
        int _next;

        void Awake()
        {
            foreach (var ev in Events)
            {
                var clip = Resources.Load<AudioClip>("Audio/" + ev);
                if (clip != null) _clips[ev] = clip;
            }
            for (int i = 0; i < VoiceCount; i++)
            {
                var src = gameObject.AddComponent<AudioSource>();
                src.playOnAwake = false;
                _voices.Add(src);
            }
        }

        public void Play(string ev)
        {
            // Haptics fire regardless of mute — audio and vibration are separate concerns.
            if (HapticsEnabled)
            {
                int ms;
                if (HapticMs.TryGetValue(ev, out ms) && ms > 0) Haptics.Vibrate(ms);
            }

            if (Muted) return;
            AudioClip clip;
            if (!_clips.TryGetValue(ev, out clip)) return;
            var voice = _voices[_next];
            _next = (_next + 1) % _voices.Count;
            voice.clip = clip;
            voice.Play();
        }

        public static string EventName(EffectType t)
        {
            switch (t)
            {
                case EffectType.BombExplode: return "bomb_explode";
                case EffectType.MagnetPull: return "magnet_pull";
                default: return "hourglass_use";
            }
        }
    }

    /// <summary>Short vibration pulses. Handheld.Vibrate() has no duration, so Android uses the Vibrator API.</summary>
    public static class Haptics
    {
        public static void Vibrate(int ms)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using (var unity = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                using (var activity = unity.GetStatic<AndroidJavaObject>("currentActivity"))
                using (var vibrator = activity.Call<AndroidJavaObject>("getSystemService", "vibrator"))
                {
                    if (vibrator != null) { vibrator.Call("vibrate", (long)ms); return; }
                }
            }
            catch (System.Exception) { /* fall through to the fixed-length buzz */ }
            Handheld.Vibrate(); // also makes Unity add the VIBRATE permission to the manifest
#elif UNITY_IOS && !UNITY_EDITOR
            Handheld.Vibrate();
#endif
        }
    }
}
