using System;
using System.IO;
using UnityEngine;

namespace HueHaven
{
    /// <summary>
    /// Saved progress (stars per level, highest unlocked level) and settings.
    /// Stored as JSON in persistentDataPath. Port of scripts/Progression.gd.
    /// </summary>
    public sealed class Progression
    {
        [Serializable]
        sealed class SaveData
        {
            public int unlocked;
            public int[] stars = new int[LevelGenerator.TotalLevels];
            public bool colorblind;
            public bool muted;
            public bool haptics = true;
        }

        SaveData _data = new SaveData();
        readonly string _path;

        public Progression(string path = null)
        {
            _path = path ?? Path.Combine(Application.persistentDataPath, "huehaven_save.json");
            Load();
        }

        // --- Stars ---

        public int GetStars(int levelIdx)
        {
            return levelIdx >= 0 && levelIdx < _data.stars.Length ? _data.stars[levelIdx] : 0;
        }

        /// <summary>Only ever improves a level's rating.</summary>
        public void SetStars(int levelIdx, int stars)
        {
            if (levelIdx < 0 || levelIdx >= _data.stars.Length) return;
            if (stars > _data.stars[levelIdx])
            {
                _data.stars[levelIdx] = Mathf.Min(stars, 3);
                Save();
            }
        }

        public int HighestUnlocked { get { return _data.unlocked; } }

        public void UnlockLevel(int levelIdx)
        {
            if (levelIdx > _data.unlocked)
            {
                _data.unlocked = levelIdx;
                Save();
            }
        }

        public bool IsLevelUnlocked(int levelIdx) { return levelIdx <= _data.unlocked; }

        public int TotalStars()
        {
            int sum = 0;
            foreach (var s in _data.stars) sum += s;
            return sum;
        }

        public int PackStars(int startIdx, int count)
        {
            int sum = 0;
            for (int i = 0; i < count; i++) sum += GetStars(startIdx + i);
            return sum;
        }

        // --- Settings ---

        public bool Colorblind { get { return _data.colorblind; } set { _data.colorblind = value; Save(); } }
        public bool Muted { get { return _data.muted; } set { _data.muted = value; Save(); } }
        public bool Haptics { get { return _data.haptics; } set { _data.haptics = value; Save(); } }

        // --- Save / load ---

        public void Save()
        {
            try { File.WriteAllText(_path, JsonUtility.ToJson(_data)); }
            catch (Exception e) { Debug.LogWarning("HueHaven: could not save progress: " + e.Message); }
        }

        public void Load()
        {
            _data = new SaveData();
            try
            {
                if (File.Exists(_path))
                {
                    var loaded = JsonUtility.FromJson<SaveData>(File.ReadAllText(_path));
                    if (loaded != null) _data = loaded;
                }
            }
            catch (Exception e) { Debug.LogWarning("HueHaven: could not read save, starting fresh: " + e.Message); }

            if (_data.stars == null || _data.stars.Length != LevelGenerator.TotalLevels)
            {
                var fixedStars = new int[LevelGenerator.TotalLevels];
                if (_data.stars != null) Array.Copy(_data.stars, fixedStars, Mathf.Min(_data.stars.Length, fixedStars.Length));
                _data.stars = fixedStars;
            }
            if (_data.unlocked < 0) _data.unlocked = 0; // level 0 is always unlocked
        }

        /// <summary>Wipes progress but keeps the player's settings.</summary>
        public void ResetAll()
        {
            _data.unlocked = 0;
            _data.stars = new int[LevelGenerator.TotalLevels];
            Save();
        }
    }
}
