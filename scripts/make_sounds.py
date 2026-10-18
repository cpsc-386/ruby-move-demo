# Synthesizes the game's sound effects as 44.1 kHz mono 16-bit WAV files:
#   suck.wav      - played when the circles spiral in to the click
#   explosion.wav - played when the circles are sent home
#
# Usage: python3 scripts/make_sounds.py [output_dir]
#        (default: mygame/sounds)
import math, os, random, struct, sys, wave

DEFAULT_OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "mygame", "sounds")

RATE = 44100
random.seed(7)

def write(path, samples):
    peak = max(abs(s) for s in samples)
    scale = 0.9 / peak                    # normalize to -1 dBFS-ish, never clips
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))

class SVF:
    """Chamberlin state-variable filter; returns (low, band)."""
    def __init__(self): self.low = self.band = 0.0
    def step(self, x, cutoff, damping):
        f = 2 * math.sin(math.pi * min(cutoff, RATE / 6) / RATE)
        self.low += f * self.band
        high = x - self.low - damping * self.band
        self.band += f * high
        return self.low, self.band

def suck(duration=1.1):
    # Noise through a resonant band-pass sweeping upward while it swells, like
    # air rushing into a drain, ending in a short low "gulp".
    n = int(duration * RATE); out = []; svf = SVF(); gulp_phase = 0.0
    for i in range(n):
        t = i / n
        cutoff = 250 * (3200 / 250) ** (t ** 1.5)
        _, band = svf.step(random.uniform(-1, 1), cutoff, 0.35)
        swell = t ** 1.3 if t < 0.88 else 0.88 ** 1.3 * (1 - (t - 0.88) / 0.12) ** 2
        s = band * swell
        if t > 0.8:                                   # the gulp
            g = (t - 0.8) / 0.2
            gulp_phase += 2 * math.pi * (180 - 120 * g) / RATE
            s += 0.5 * math.sin(gulp_phase) * math.sin(math.pi * g)
        out.append(s)
    return out

def explosion(duration=1.8):
    # Sharp noise burst whose brightness and loudness decay, over a low thump
    # that drops in pitch; a little crackle in the first moments.
    n = int(duration * RATE); out = []; svf = SVF(); thump_phase = 0.0
    for i in range(n):
        sec = i / RATE
        attack = min(1.0, sec / 0.004)
        cutoff = 150 + 5000 * math.exp(-sec * 5)
        low, _ = svf.step(random.uniform(-1, 1), cutoff, 1.2)
        noise = low * math.exp(-sec * 2.8)
        thump_phase += 2 * math.pi * (40 + 70 * math.exp(-sec * 12)) / RATE
        thump = math.sin(thump_phase) * math.exp(-sec * 5) * 0.9
        crackle = (random.uniform(-1, 1) if random.random() < 0.02 else 0) * math.exp(-sec * 9) * 0.6
        out.append(attack * (noise * 1.6 + thump + crackle))
    return out

out_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUTPUT_DIR
write(os.path.join(out_dir, "suck.wav"), suck())
write(os.path.join(out_dir, "explosion.wav"), explosion())
