#!/usr/bin/env python3
"""Synthesizes the game's first sound pass: ambience, footsteps, puzzle and cinematic effects, breathing and music.

Everything is made here from noise, oscillators and filters, with fixed seeds, so the output is original, reproducible in content (Ogg gives each file a random stream serial, so the bytes differ),
and the project's own. No recording, sample library or model is used. Needs numpy, scipy and soundfile.

    python tools/audio/make_sounds.py            writes project/assets/audio/**.ogg and prints a measurement table
    python tools/audio/make_sounds.py --check    measures what is there, and fails on clipping or a broken loop

This is an initial pass to put sound in every scene and event. It is not final production audio, and it has been
measured, not listened to, by the developer (docs/evidence/m3/audio/README.md).
"""

import argparse
import math
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, fftconvolve, sosfilt

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project" / "assets" / "audio"


# ---------------------------------------------------------------- building blocks


def seconds(s):
    return int(round(s * SR))


def t_axis(n):
    return np.arange(n) / SR


def white(n, rng):
    return rng.standard_normal(n)


def pink(n, rng):
    spectrum = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    spectrum /= np.sqrt(f)
    x = np.fft.irfft(spectrum, n)
    return x / (np.std(x) + 1e-12)


def brown(n, rng):
    x = np.cumsum(rng.standard_normal(n))
    x = sosfilt(butter(1, 8, "high", fs=SR, output="sos"), x)
    return x / (np.std(x) + 1e-12)


def filt(x, kind, freq, order=2):
    return sosfilt(butter(order, freq, kind, fs=SR, output="sos"), x)


def smooth_random(n, rng, period, low=0.0, high=1.0):
    """A slowly wandering control signal, for swells, gusts and drift."""
    points = max(4, int(n / (period * SR)) + 3)
    knots = rng.uniform(low, high, points)
    xs = np.linspace(0, n, points)
    return np.interp(np.arange(n), xs, knots) if points > 1 else np.full(n, knots[0])


def env_exp(n, tau):
    return np.exp(-t_axis(n) / max(tau, 1e-4))


def adsr(n, attack, release, sustain_level=1.0):
    e = np.full(n, sustain_level)
    a = min(seconds(attack), n)
    r = min(seconds(release), n - a)
    if a:
        e[:a] = np.linspace(0, sustain_level, a)
    if r:
        e[n - r :] = np.linspace(sustain_level, 0, r) * (e[n - r] if n - r < n else 1)
    return e


def sine_sweep(n, f0, f1, curve=1.0):
    f = f0 + (f1 - f0) * (np.linspace(0, 1, n) ** curve)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def saw(n, freq):
    phase = np.cumsum(np.broadcast_to(freq, (n,)) / SR) % 1.0
    return 2 * phase - 1


def place(dest, sound, start):
    i = seconds(start) if isinstance(start, float) else start
    if i >= len(dest):
        return
    end = min(len(dest), i + len(sound))
    dest[i:end] += sound[: end - i]


def reverb(x, length, damp_hz, wet, rng, predelay=0.02):
    n = seconds(length)
    ir = white(n, rng) * env_exp(n, length / 6.0)
    ir = filt(ir, "low", damp_hz)
    ir[: seconds(predelay)] = 0
    ir /= np.sqrt(np.sum(ir**2)) + 1e-12
    tail = fftconvolve(x, ir)
    out = np.zeros(len(tail))
    out[: len(x)] += x * (1 - wet)
    out += tail * wet
    return out


def stereo(left, right):
    return np.stack([left, right])


def widen(x, rng, amount=0.4):
    """A mono sound made stereo by a short, different delay and filtering on each side."""
    d = seconds(0.011)
    right = np.concatenate([np.zeros(d), x])[: len(x)]
    left = filt(x, "low", 9000) * (1 - amount * 0.2)
    return stereo(left, (1 - amount) * x + amount * right)


def make_loop(x, crossfade):
    """Folds the tail over the head with an equal-power crossfade, so the end joins the start."""
    c = seconds(crossfade)
    if x.ndim == 1:
        x = x[None, :]
    body = x[:, :-c].copy()
    tail = x[:, -c:]
    ramp = np.linspace(0, math.pi / 2, c)
    body[:, :c] = body[:, :c] * np.sin(ramp) + tail * np.cos(ramp)
    return body if body.shape[0] > 1 else body[0]


def rms_db(x):
    return 20 * math.log10(np.sqrt(np.mean(np.square(x))) + 1e-12)


def peak_db(x):
    return 20 * math.log10(np.max(np.abs(x)) + 1e-12)


def level(x, rms=None, peak=None):
    """Sets a level by RMS or by peak, then makes sure nothing passes -1 dBFS."""
    x = x - np.mean(x, axis=-1, keepdims=True)
    if rms is not None:
        x = x * 10 ** ((rms - rms_db(x)) / 20)
    if peak is not None:
        x = x * 10 ** ((peak - peak_db(x)) / 20)
    limit = 10 ** (-1.0 / 20)
    if np.max(np.abs(x)) > limit:
        x = x * limit / np.max(np.abs(x))
    return x


def fade(x, fade_in=0.005, fade_out=0.02):
    x = x.copy()
    a, b = seconds(fade_in), seconds(fade_out)
    if x.ndim == 1:
        x = x[None, :]
        mono = True
    else:
        mono = False
    if a:
        x[:, :a] *= np.linspace(0, 1, a)
    if b:
        x[:, -b:] *= np.linspace(1, 0, b)
    return x[0] if mono else x


# ---------------------------------------------------------------- ambience (loops)


def amb_shore_sea(rng):
    """A thin, far-off sea: no surf where it should be, only a distant wash and a low swell."""
    n = seconds(26)
    out = []
    for side in range(2):
        wash = filt(pink(n, rng), "band", (90, 700))
        swell = smooth_random(n, rng, 6.5, 0.15, 1.0) ** 2
        hiss = filt(white(n, rng), "band", (900, 2600)) * 0.08 * smooth_random(n, rng, 4.0, 0.2, 1.0)
        rumble = filt(brown(n, rng), "low", 90) * 0.6
        out.append(wash * swell + hiss + rumble)
    return level(make_loop(stereo(*out), 3.0), rms=-30)


def amb_wind(rng):
    n = seconds(30)
    out = []
    gust = smooth_random(n, rng, 5.0, 0.1, 1.0) ** 1.6
    for side in range(2):
        body = filt(pink(n, rng), "band", (180, 900)) * (0.3 + gust)
        whistle_f = 520 + 160 * smooth_random(n, rng, 7.0, -1, 1)
        whistle = filt(white(n, rng), "band", (480, 760), order=4) * 0.25 * gust**2
        out.append(body + whistle + 0.0 * whistle_f)
    return level(make_loop(stereo(*out), 3.0), rms=-32)


def drip(rng):
    n = seconds(0.18)
    f0 = rng.uniform(1100, 2400)
    tone = sine_sweep(n, f0, f0 * 0.62, 0.5) * env_exp(n, 0.035)
    return tone * rng.uniform(0.4, 1.0)


def amb_cave(rng):
    """Close, still air with a low resonance, and water dripping somewhere behind."""
    n = seconds(22)
    room = filt(brown(n, rng), "low", 160) * 0.5
    hum_f = 52 + 1.5 * smooth_random(n, rng, 6.0, -1, 1)
    hum = np.sin(2 * np.pi * np.cumsum(hum_f) / SR) * 0.12 * smooth_random(n, rng, 5.0, 0.4, 1.0)
    air = filt(pink(n, rng), "band", (120, 500)) * 0.25 * smooth_random(n, rng, 8.0, 0.3, 1.0)
    drips = np.zeros(n)
    time = 0.7
    while time < 20.5:
        place(drips, drip(rng) * 0.6, time)
        time += rng.uniform(1.1, 3.4)
    drips = reverb(drips, 2.4, 3500, 0.75, rng)[:n]
    mono = room + hum + air + drips
    return level(make_loop(widen(mono, rng, 0.5), 1.5), rms=-31)


def groan(rng, length):
    n = seconds(length)
    f = rng.uniform(38, 62) * (1 + 0.06 * smooth_random(n, rng, length / 3, -1, 1))
    tone = saw(n, f)
    tone = filt(tone, "band", (60, 320))
    return tone * np.sin(np.linspace(0, math.pi, n)) ** 2


def amb_abyss(rng):
    """Wind over open mud, a far groan now and then, and the mud itself settling."""
    n = seconds(32)
    out = []
    groans = np.zeros(n)
    for start in (3.0, 15.5, 25.0):
        place(groans, groan(rng, rng.uniform(3.5, 5.5)) * rng.uniform(0.25, 0.45), start)
    groans = reverb(groans, 3.0, 1200, 0.6, rng)[:n]
    bubbles = np.zeros(n)
    time = 1.0
    while time < 30:
        m = seconds(0.09)
        f = rng.uniform(70, 190)
        place(bubbles, sine_sweep(m, f, f * 1.8) * env_exp(m, 0.02) * rng.uniform(0.2, 0.5), time)
        time += rng.uniform(0.4, 2.8)
    for side in range(2):
        wind = filt(pink(n, rng), "band", (110, 520)) * (0.35 + smooth_random(n, rng, 6.0, 0.0, 0.8))
        sub = filt(brown(n, rng), "low", 60) * 0.7
        out.append(wind + sub + groans + filt(bubbles, "low", 900) * (0.9 if side else 0.7))
    return level(make_loop(stereo(*out), 3.0), rms=-28)


def amb_monolith(rng):
    """A drone the stone seems to hold: slow beating fifths under a breath of air."""
    n = seconds(24)
    t = t_axis(n)
    out = []
    for side, detune in ((0, 0.0), (1, 0.21)):
        tones = sum(a * np.sin(2 * np.pi * (f + detune) * t + rng.uniform(0, 6)) for f, a in ((41.2, 1.0), (61.8, 0.55), (82.4, 0.35), (123.6, 0.12)))
        tones *= 0.6 + 0.4 * smooth_random(n, rng, 6.0, 0.3, 1.0)
        breath = filt(pink(n, rng), "band", (200, 800)) * 0.18 * smooth_random(n, rng, 5.0, 0.2, 1.0)
        out.append(tones * 0.35 + breath)
    return level(make_loop(stereo(*out), 3.0), rms=-29)


# ---------------------------------------------------------------- footsteps


def step_sand(rng, heavy=False):
    n = seconds(0.32 if heavy else 0.22)
    press = filt(white(n, rng), "low", 1400) * env_exp(n, 0.05 if heavy else 0.03)
    squelch = filt(white(n, rng), "band", (260, 820)) * env_exp(n, 0.07) * np.clip(np.sin(np.linspace(0, math.pi, n)) * 2, 0, 1)
    thump = np.sin(2 * np.pi * 85 * t_axis(n)) * env_exp(n, 0.03) * (0.8 if heavy else 0.4)
    return fade(level(press + 0.6 * squelch + thump, peak=-8 if heavy else -11))


def step_rock(rng, heavy=False):
    n = seconds(0.25 if heavy else 0.16)
    click = filt(white(n, rng), "high", 2200) * env_exp(n, 0.006)
    scuff = filt(white(n, rng), "band", (600, 3000)) * env_exp(n, 0.03) * 0.4
    thump = np.sin(2 * np.pi * rng.uniform(110, 140) * t_axis(n)) * env_exp(n, 0.035) * (0.9 if heavy else 0.55)
    x = reverb(click + scuff + thump, 0.5, 4000, 0.18, rng)[:n]
    return fade(level(x, peak=-8 if heavy else -11))


# ---------------------------------------------------------------- the monolith


def stone_slide(rng, length):
    n = seconds(length)
    grit = filt(white(n, rng), "band", (350, 1600)) * (0.5 + 0.5 * np.abs(filt(white(n, rng), "low", 30)))
    return grit * np.sin(np.linspace(0, math.pi, n)) ** 0.6


def stone_accept(rng):
    n = seconds(2.4)
    x = np.zeros(n)
    place(x, stone_slide(rng, 0.45) * 0.5, 0)
    t = t_axis(n)
    tone = (np.sin(2 * np.pi * 220 * t) + 0.5 * np.sin(2 * np.pi * 330 * t) + 0.2 * np.sin(2 * np.pi * 440.7 * t))
    tone *= np.minimum(t / 0.35, 1) * np.exp(-t / 0.9)
    x += tone * 0.35
    return fade(level(reverb(x, 1.8, 5000, 0.35, rng), peak=-6))


def stone_reject(rng):
    n = seconds(1.6)
    x = np.zeros(n)
    place(x, stone_slide(rng, 0.9) * 0.9, 0)
    grind = filt(saw(seconds(0.9), 34 + 8 * smooth_random(seconds(0.9), rng, 0.2, -1, 1)), "low", 500) * 0.5
    place(x, grind * np.sin(np.linspace(0, math.pi, len(grind))), 0.0)
    thud = np.sin(2 * np.pi * 55 * t_axis(seconds(0.5))) * env_exp(seconds(0.5), 0.12)
    place(x, thud, 0.85)
    return fade(level(reverb(x, 1.2, 2500, 0.3, rng), peak=-5))


def gate_open(rng):
    n = seconds(4.2)
    x = np.zeros(n)
    rumble = filt(brown(seconds(3.6), rng), "low", 140) * np.sin(np.linspace(0, math.pi, seconds(3.6))) ** 0.8
    place(x, rumble * 1.2, 0)
    place(x, stone_slide(rng, 3.2) * 0.6, 0.2)
    thud = np.sin(2 * np.pi * 42 * t_axis(seconds(1.0))) * env_exp(seconds(1.0), 0.25)
    place(x, thud * 1.1, 3.3)
    return fade(level(reverb(x, 2.6, 1800, 0.4, rng)[:n], peak=-4), fade_out=0.3)


def debris(rng, length, density):
    n = seconds(length)
    x = np.zeros(n)
    time = 0.0
    while time < length - 0.05:
        m = seconds(0.05)
        place(x, filt(white(m, rng), "band", (900, 5000)) * env_exp(m, 0.008) * rng.uniform(0.2, 1.0), time)
        time += rng.exponential(1.0 / density)
    return x * np.exp(-t_axis(n) / (length / 2.5))


def impact(rng, freq, tau, crack=0.5):
    n = seconds(max(tau * 6, 0.4))
    boom = sine_sweep(n, freq * 1.4, freq * 0.75, 0.3) * env_exp(n, tau)
    burst = filt(white(n, rng), "low", 2500) * env_exp(n, 0.03) * crack
    return boom + burst


def slab_fall(rng):
    n = seconds(3.0)
    x = np.zeros(n)
    creak_n = seconds(0.55)
    creak = filt(white(creak_n, rng), "band", (180, 700), order=4) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * t_axis(creak_n)))
    place(x, creak * np.linspace(0.2, 1, creak_n), 0.0)
    place(x, impact(rng, 60, 0.35, 0.9) * 1.3, 0.5)
    place(x, debris(rng, 1.4, 18) * 0.5, 0.55)
    return fade(level(reverb(x, 2.0, 2200, 0.35, rng)[:n], peak=-3), fade_out=0.2)


# ---------------------------------------------------------------- the reveal


def water_surge(rng):
    n = seconds(6.0)
    swell = np.sin(np.linspace(0, math.pi, n)) ** 1.5
    out = []
    for side in range(2):
        rush = filt(pink(n, rng), "band", (120, 3500)) * swell
        spray = filt(white(n, rng), "high", 3000) * 0.12 * swell**3
        sub = np.sin(2 * np.pi * 33 * t_axis(n)) * 0.5 * swell
        out.append(rush + spray + sub)
    return fade(level(stereo(*out), peak=-3), fade_out=0.4)


def creature_call(rng):
    """Deep and rhythmic: a vast throat, pulsing slower than breathing, falling at the end."""
    n = seconds(7.5)
    t = t_axis(n)
    f0 = 36 + 4 * np.sin(2 * np.pi * 0.11 * t) - 7 * np.clip((t - 5.5) / 2.0, 0, 1)
    voice = np.zeros(n)
    phase = np.cumsum(f0 / SR)
    for k in range(1, 26):
        voice += np.sin(2 * np.pi * k * phase) / k ** 0.9
    growl = 1 + 0.35 * np.sin(2 * np.pi * 18.5 * t)
    pulse = 0.35 + 0.65 * (0.5 + 0.5 * np.sin(2 * np.pi * 1.55 * t - math.pi / 2)) ** 2
    shape = np.minimum(t / 0.8, 1) * np.clip((7.5 - t) / 1.2, 0, 1)
    voice = voice * growl * pulse * shape
    formant = filt(voice, "band", (90, 420)) + 0.4 * filt(voice, "band", (520, 900))
    breath = filt(pink(n, rng), "band", (80, 600)) * 0.3 * pulse * shape
    x = reverb(formant + breath, 4.0, 900, 0.5, rng)
    return fade(level(widen(x[: n + seconds(3)], rng, 0.6), peak=-3), fade_out=0.8)


def hand_impact(rng):
    n = seconds(5.0)
    x = np.zeros(n)
    place(x, impact(rng, 32, 0.9, 1.2) * 1.6, 0.0)
    place(x, filt(white(seconds(0.08), rng), "high", 1500) * env_exp(seconds(0.08), 0.015) * 0.9, 0.0)
    place(x, debris(rng, 3.0, 30) * 0.6, 0.15)
    return fade(level(widen(reverb(x, 3.5, 1500, 0.4, rng)[:n], rng, 0.5), peak=-1.5), fade_out=0.5)


# ---------------------------------------------------------------- escape and collapse


def rock_fall(rng):
    n = seconds(1.6)
    x = np.zeros(n)
    place(x, impact(rng, rng.uniform(65, 85), 0.18, 0.8), 0.0)
    place(x, debris(rng, 1.2, 25) * 0.45, 0.04)
    return fade(level(reverb(x, 1.0, 3000, 0.25, rng)[:n], peak=-4), fade_out=0.2)


def tide_roar(rng):
    n = seconds(14)
    out = []
    churn = smooth_random(n, rng, 1.2, 0.55, 1.0)
    for side in range(2):
        rush = filt(pink(n, rng), "band", (90, 4200)) * churn
        low = filt(brown(n, rng), "low", 110) * 0.8
        out.append(rush + low)
    return level(make_loop(stereo(*out), 2.0), rms=-20)


def body_fall(rng):
    n = seconds(1.2)
    x = np.zeros(n)
    place(x, impact(rng, 95, 0.08, 0.3), 0.0)
    place(x, impact(rng, 80, 0.06, 0.25) * 0.6, 0.22)
    place(x, filt(white(seconds(0.5), rng), "band", (300, 1500)) * env_exp(seconds(0.5), 0.12) * 0.3, 0.25)
    return fade(level(x, peak=-5))


def sea_rush(rng):
    n = seconds(4.0)
    rise = np.linspace(0, 1, n) ** 1.8
    out = []
    for side in range(2):
        out.append(filt(pink(n, rng), "band", (100, 3000)) * rise + filt(brown(n, rng), "low", 80) * rise)
    return fade(level(stereo(*out), peak=-3), fade_out=0.1)


# ---------------------------------------------------------------- the sailor's breathing


def breath(rng, inhale, exhale, strength, rough=0.0):
    a, b = seconds(inhale), seconds(exhale)
    inn = filt(white(a, rng), "band", (900, 3200)) * np.sin(np.linspace(0, math.pi, a)) ** 1.3
    out = filt(white(b, rng), "band", (380, 1600)) * np.sin(np.linspace(0, math.pi, b)) ** 1.1 * 0.8
    if rough:
        out *= 1 + rough * np.abs(filt(white(b, rng), "low", 25)) * 2
    return np.concatenate([inn, out]) * strength


def breath_loop(rng, pattern, length):
    n = seconds(length)
    x = np.zeros(n + seconds(3))
    time = 0.2
    for inhale, exhale, gap, strength, rough in pattern:
        place(x, breath(rng, inhale, exhale, strength, rough), time)
        time += inhale + exhale + gap
    x = x[: n + seconds(0.8)]
    return x


def breath_tired(rng):
    pattern = [(1.3, 1.9, 2.2, 1.0, 0.0), (1.1, 2.1, 2.4, 0.8, 0.1)]
    return level(make_loop(breath_loop(rng, pattern, 12.0), 0.8), rms=-34)


def breath_uneasy(rng):
    pattern = [(0.8, 1.0, 0.9, 0.9, 0.1), (0.7, 1.1, 1.2, 0.8, 0.0), (0.8, 0.9, 0.8, 1.0, 0.15)]
    return level(make_loop(breath_loop(rng, pattern, 8.4), 0.6), rms=-33)


def breath_panic(rng):
    pattern = [(0.32, 0.38, 0.06, 1.0, 0.4)] * 4 + [(0.5, 0.45, 0.05, 1.1, 0.6)] + [(0.3, 0.36, 0.05, 0.9, 0.4)] * 3
    return level(make_loop(breath_loop(rng, pattern, 6.0), 0.4), rms=-26)


def gasp(rng):
    n = seconds(0.9)
    x = np.zeros(n)
    place(x, filt(white(seconds(0.35), rng), "band", (1000, 4200)) * np.sin(np.linspace(0, math.pi, seconds(0.35))) ** 0.7, 0.02)
    place(x, filt(white(seconds(0.4), rng), "band", (400, 1500)) * env_exp(seconds(0.4), 0.15) * 0.35, 0.42)
    return fade(level(x, peak=-9))


# ---------------------------------------------------------------- background events


def ritual_drum(rng):
    n = seconds(13.0)
    x = np.zeros(n)
    time = 0.6
    while time < 12.0:
        m = seconds(0.7)
        hit = sine_sweep(m, 92, 58, 0.4) * env_exp(m, 0.16) + filt(white(m, rng), "low", 600) * env_exp(m, 0.02) * 0.4
        place(x, hit * rng.uniform(0.7, 1.0), time)
        time += rng.choice([1.05, 1.05, 0.55]) + rng.uniform(-0.03, 0.03)
    t = t_axis(n)
    chant = filt(saw(n, 98 + 1.2 * np.sin(2 * np.pi * 0.2 * t)), "band", (200, 700)) * 0.12
    chant *= np.minimum(t / 2.0, 1) * np.clip((13 - t) / 2.0, 0, 1)
    far = filt(x + chant, "low", 900)
    return fade(level(widen(reverb(far, 3.0, 1200, 0.55, rng)[:n], rng, 0.5), rms=-27), fade_out=1.0)


# ---------------------------------------------------------------- music


def note(freq):
    return 440.0 * 2 ** ((freq - 69) / 12)


def pad(n, midi_notes, rng, brightness=900, detune=0.12):
    t = t_axis(n)
    x = np.zeros(n)
    for m in midi_notes:
        f = note(m)
        for d in (-detune, 0.0, detune):
            x += saw(n, f * (1 + d / 100)) * 0.33
    x = filt(x, "low", brightness)
    return x / max(len(midi_notes), 1)


def bowed(n, midi, rng):
    t = t_axis(n)
    f = note(midi) * (1 + 0.003 * np.sin(2 * np.pi * 5.1 * t))
    x = sum(np.sin(2 * np.pi * k * np.cumsum(f) / SR) / k**1.4 for k in range(1, 7))
    shape = np.minimum(t / 0.6, 1) * np.clip((len(t) / SR - t) / 0.8, 0, 1)
    return filt(x, "low", 2400) * shape


def pluck(n, midi):
    t = t_axis(n)
    f = note(midi)
    x = sum(np.sin(2 * np.pi * k * f * t) * np.exp(-t * (1.2 + k * 0.9)) / k for k in range(1, 6))
    return x * np.minimum(t / 0.004, 1)


def music_prologue(rng):
    """Slow and far away: a minor progression under one bowed line. The sea, before anything is wrong."""
    chord_len = 9.0
    chords = [(50, 57, 62, 65), (46, 53, 58, 62), (43, 50, 55, 58), (45, 52, 57, 61)]
    n = seconds(chord_len * len(chords) + 6)
    x = np.zeros(n)
    for i, chord in enumerate(chords):
        m = seconds(chord_len + 3)
        p = pad(m, chord, rng, brightness=700) * adsr(m, 2.5, 3.0)
        place(x, p, i * chord_len)
    for start, midi, length in ((3.0, 74, 4.0), (8.5, 72, 3.0), (12.5, 70, 5.0), (21.0, 69, 3.5), (25.5, 67, 4.0), (30.5, 69, 5.5)):
        place(x, bowed(seconds(length), midi, rng) * 0.35, start)
    return fade(level(widen(reverb(x, 4.0, 3000, 0.45, rng)[:n], rng, 0.7), rms=-23), fade_out=3.0)


def music_awaken(rng):
    """The stones answer: a low cluster that tightens and swells, then holds."""
    n = seconds(9.0)
    t = t_axis(n)
    x = pad(n, (38, 45, 46, 50), rng, brightness=500 + 1400 * np.clip(t[-1] / 9, 0, 1))
    x = filt(x, "low", 1600)
    tremolo = 0.8 + 0.2 * np.sin(2 * np.pi * 6.0 * t)
    swell = np.minimum(t / 5.5, 1) ** 2 * np.clip((9 - t) / 2.5, 0.35, 1)
    sub = np.sin(2 * np.pi * note(26) * t) * 0.5 * swell
    return fade(level(widen(reverb(x * tremolo * swell + sub, 3.5, 2500, 0.4, rng)[:n], rng, 0.6), rms=-20), fade_out=1.5)


def music_reveal(rng):
    """Deep and slow, building to the hand on the stone at 7 s, then left hanging."""
    n = seconds(16.0)
    t = t_axis(n)
    build = np.clip(t / 7.0, 0, 1) ** 2.2
    after = np.where(t > 7.0, np.exp(-(t - 7.0) / 5.0), 1.0)
    brass = pad(n, (26, 33, 38, 39), rng, brightness=300, detune=0.25)
    # The brass opens as it builds: a dark and a bright version, crossfaded.
    brass = filt(brass, "low", 220) * (1 - build) + filt(brass, "low", 1400) * build
    sub = np.sin(2 * np.pi * note(26) * t) * build * 0.8
    x = (brass * 1.4 + sub) * build * after
    hit = np.zeros(n)
    place(hit, impact(rng, 40, 1.2, 0.4), 7.0)
    return fade(level(widen(reverb(x + hit * 0.6, 4.0, 1500, 0.45, rng)[:n], rng, 0.6), rms=-19), fade_out=2.0)


def music_ending(rng):
    """A restrained resolution: the same minor colour opening out, and a few notes left in the quiet."""
    chord_len = 10.0
    chords = [(50, 57, 62, 65), (46, 53, 58, 62), (41, 48, 53, 57), (50, 57, 62, 66)]
    n = seconds(chord_len * len(chords) + 8)
    x = np.zeros(n)
    for i, chord in enumerate(chords):
        m = seconds(chord_len + 4)
        place(x, pad(m, chord, rng, brightness=800) * adsr(m, 3.0, 4.0), i * chord_len)
    for start, midi in ((4.0, 74), (9.0, 69), (15.0, 72), (21.5, 70), (28.0, 69), (35.0, 74), (41.0, 78)):
        place(x, pluck(seconds(4.0), midi) * 0.4, start)
    return fade(level(widen(reverb(x, 5.0, 3500, 0.5, rng)[:n], rng, 0.7), rms=-24), fade_out=5.0)


def music_cave(rng):
    """Restrained, for the cave: a low held fifth that hardly moves, and a few distant tones, far apart, like water
    finding a note in the dark. Mostly space. Fades out as the cave opens."""
    n = seconds(56.0)
    t = t_axis(n)
    drone = (np.sin(2 * np.pi * note(38) * t) + 0.6 * np.sin(2 * np.pi * note(45) * t * 1.0007)) * 0.25
    drone *= np.minimum(t / 8.0, 1) * np.clip((56 - t) / 14.0, 0, 1)
    tones = np.zeros(n)
    for start, midi in ((6.0, 69), (15.5, 72), (24.0, 67), (33.5, 70), (44.0, 65)):
        place(tones, pluck(seconds(6.0), midi) * 0.35, start)
    x = filt(drone, "low", 700) + reverb(tones, 5.0, 2500, 0.7, rng)[:n]
    return fade(level(widen(reverb(x, 4.0, 2000, 0.4, rng)[:n], rng, 0.7), rms=-28), fade_out=6.0)


def amb_night_sea(rng):
    """For the epilogue: the sea that never left. Small waves on a shingle shore at night, close and quiet."""
    n = seconds(24)
    out = []
    for side in range(2):
        wash = np.zeros(n)
        time = 0.5 + side * 0.4
        while time < 22.0:
            m = seconds(rng.uniform(2.2, 3.4))
            swell = np.sin(np.linspace(0, math.pi, m)) ** 2
            place(wash, filt(pink(m, rng), "band", (150, 3200)) * swell, time)
            time += rng.uniform(2.8, 4.2)
        hiss = filt(white(n, rng), "band", (2500, 6000)) * 0.05
        out.append(wash + hiss + filt(brown(n, rng), "low", 90) * 0.3)
    return level(make_loop(stereo(*out), 2.0), rms=-30)


def water_cascade(rng):
    """Water pouring off something huge as it rises: a broad roar, breaking up into heavy falling sheets."""
    n = seconds(7.0)
    t = t_axis(n)
    shape = np.minimum(t / 0.8, 1) * np.clip((7 - t) / 3.0, 0, 1)
    out = []
    for side in range(2):
        roar = filt(pink(n, rng), "band", (180, 5000)) * shape
        sheets = np.zeros(n)
        time = 0.4
        while time < 6.0:
            m = seconds(0.5)
            place(sheets, filt(white(m, rng), "band", (300, 2400)) * env_exp(m, 0.18) * rng.uniform(0.3, 0.8), time)
            time += rng.uniform(0.15, 0.5)
        out.append(roar + sheets * shape)
    return fade(level(stereo(*out), peak=-3), fade_out=0.5)


# ---------------------------------------------------------------- the list


SOUNDS = {
    # path under assets/audio: (maker, loops, what it is for)
    "ambience/shore_sea.ogg": (amb_shore_sea, True, "The Shore: a thin, far-off sea"),
    "ambience/wind.ogg": (amb_wind, True, "The Shore and the open abyss: wind"),
    "ambience/cave.ogg": (amb_cave, True, "The cave: still air, a low resonance, drips"),
    "ambience/abyss.ogg": (amb_abyss, True, "The Exposed Abyss: wind on mud, far groans, settling mud"),
    "ambience/monolith.ogg": (amb_monolith, True, "The monolith: a held drone"),
    "ambience/tide_roar.ogg": (tide_roar, True, "The escape: the returning sea, following him"),
    "footsteps/sand_1.ogg": (lambda r: step_sand(r), False, "Footstep, wet sand and mud"),
    "footsteps/sand_2.ogg": (lambda r: step_sand(r), False, "Footstep, wet sand and mud"),
    "footsteps/sand_3.ogg": (lambda r: step_sand(r), False, "Footstep, wet sand and mud"),
    "footsteps/sand_4.ogg": (lambda r: step_sand(r, True), False, "Landing, wet sand and mud"),
    "footsteps/rock_1.ogg": (lambda r: step_rock(r), False, "Footstep, rock"),
    "footsteps/rock_2.ogg": (lambda r: step_rock(r), False, "Footstep, rock"),
    "footsteps/rock_3.ogg": (lambda r: step_rock(r), False, "Footstep, rock"),
    "footsteps/rock_4.ogg": (lambda r: step_rock(r, True), False, "Landing, rock"),
    "effects/stone_accept.ogg": (stone_accept, False, "A stone accepts: a slide and a soft tone"),
    "effects/stone_reject.ogg": (stone_reject, False, "The stones reject: a grind and a thud"),
    "effects/gate_open.ogg": (gate_open, False, "The gate rises"),
    "effects/slab_fall.ogg": (slab_fall, False, "The slab comes down across the gap"),
    "effects/water_surge.ogg": (water_surge, False, "The reveal: water displaced"),
    "effects/creature_call.ogg": (creature_call, False, "The reveal: its call, deep and rhythmic"),
    "effects/hand_impact.ogg": (hand_impact, False, "The reveal: the hand on the stone"),
    "effects/rock_fall_1.ogg": (rock_fall, False, "The escape: rock comes down"),
    "effects/rock_fall_2.ogg": (rock_fall, False, "The escape: rock comes down"),
    "effects/rock_fall_3.ogg": (rock_fall, False, "The escape: rock comes down"),
    "effects/body_fall.ogg": (body_fall, False, "The collapse: he falls"),
    "effects/sea_rush.ogg": (sea_rush, False, "The collapse: the sea comes over him"),
    "effects/ritual_drum.ogg": (ritual_drum, False, "The ritual, far off: a drum and a low hum"),
    "voice/breath_tired.ogg": (breath_tired, True, "His breathing, spent"),
    "voice/breath_uneasy.ogg": (breath_uneasy, True, "His breathing, uneasy"),
    "voice/breath_panic.ogg": (breath_panic, True, "His breathing, running"),
    "voice/gasp.ogg": (gasp, False, "His gasp at the reveal"),
    "music/prologue.ogg": (music_prologue, False, "Music: the prologue"),
    "music/awaken.ogg": (music_awaken, False, "Music: the stones answer"),
    "music/reveal.ogg": (music_reveal, False, "Music: the reveal"),
    "music/ending.ogg": (music_ending, False, "Music: the ending"),
    "music/cave.ogg": (music_cave, False, "Music: the cave, restrained"),
    "ambience/night_sea.ogg": (amb_night_sea, True, "The epilogue: the sea at night, close and quiet"),
    "effects/water_cascade.ogg": (water_cascade, False, "The reveal: water pouring off it as it rises"),
}


def write_ogg(path, x):
    """In blocks: libsndfile's Vorbis encoder has crashed here when handed a long sound in one call."""
    frames = x.T if x.ndim > 1 else x[:, None]
    with sf.SoundFile(path, "w", SR, frames.shape[1], format="OGG", subtype="VORBIS") as out:
        for start in range(0, frames.shape[0], 32768):
            out.write(frames[start : start + 32768])


def seed_for(path):
    return sum((i + 1) * ord(c) for i, c in enumerate(path)) % (2**31)


def seam_jump(x):
    """How big the step is from the last sample back to the first, against the sound's own typical step."""
    x = np.atleast_2d(x)
    steps = np.abs(np.diff(x, axis=1))
    typical = np.percentile(steps, 99) + 1e-9
    return float(np.max(np.abs(x[:, -1] - x[:, 0])) / typical)


def measure(path, loops):
    data, rate = sf.read(path, always_2d=True)
    x = data.T
    return {
        "seconds": x.shape[1] / rate,
        "channels": x.shape[0],
        "peak": peak_db(x),
        "rms": rms_db(x),
        "seam": seam_jump(x) if loops else 0.0,
        "dc": float(np.max(np.abs(np.mean(x, axis=1)))),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    problems = 0
    print(f"{'file':34} {'s':>6} {'ch':>2} {'peak':>7} {'rms':>7} {'seam':>5}  use")
    for rel, (maker, loops, use) in SOUNDS.items():
        path = OUT / rel
        if not args.check:
            rng = np.random.default_rng(seed_for(rel))
            x = np.asarray(maker(rng), dtype=np.float64)
            path.parent.mkdir(parents=True, exist_ok=True)
            write_ogg(path, x)
        if not path.exists():
            print(f"MISSING {rel}")
            problems += 1
            continue
        m = measure(path, loops)
        bad = []
        if m["peak"] > -0.3:
            bad.append("near clipping")
        if loops and m["seam"] > 3.0:
            bad.append("loop seam")
        if m["dc"] > 0.01:
            bad.append("DC offset")
        problems += bool(bad)
        print(f"{rel:34} {m['seconds']:6.2f} {m['channels']:2d} {m['peak']:7.1f} {m['rms']:7.1f} {m['seam']:5.2f}  {use}{'  <- ' + ', '.join(bad) if bad else ''}")
    print(f"SOUNDS files={len(SOUNDS)} problems={problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
