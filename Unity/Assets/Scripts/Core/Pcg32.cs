using System;

namespace HueHaven
{
    /// <summary>
    /// PCG32 random generator, bit-compatible with Godot 4's RandomNumberGenerator
    /// (seed -> pcg32_srandom_r with the default stream, randi() -> pcg32_random_r).
    /// Using it keeps level layouts identical to the Godot build for a given level index.
    /// </summary>
    public sealed class Pcg32
    {
        const ulong Multiplier = 6364136223846793005UL;
        const ulong DefaultInc = 1442695040888963407UL;

        ulong _state;
        ulong _inc;

        public Pcg32(ulong seed) : this(seed, DefaultInc) { }

        public Pcg32(ulong initState, ulong initSeq)
        {
            _state = 0UL;
            _inc = (initSeq << 1) | 1UL;
            NextUInt();
            _state += initState;
            NextUInt();
        }

        /// <summary>Seed from a signed value the way GDScript's `rng.seed = int` does.</summary>
        public static Pcg32 FromSeed(long seed) => new Pcg32(unchecked((ulong)seed));

        public uint NextUInt()
        {
            ulong old = _state;
            unchecked
            {
                _state = old * Multiplier + _inc;
                uint xorShifted = (uint)(((old >> 18) ^ old) >> 27);
                int rot = (int)(old >> 59);
                return (xorShifted >> rot) | (xorShifted << ((-rot) & 31));
            }
        }

        /// <summary>Equivalent of Godot's randi() % n for n > 0.</summary>
        public int NextInt(int n) => (int)(NextUInt() % (uint)n);
    }
}
