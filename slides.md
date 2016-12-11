<!--
//$size: 16:9 or a4, a3, ...
-->
<!--
$theme: default
$width: 1024
$height: 768
*template: invert
-->

**University of Leipzig**
Faculty of Mathematics and Computer Science - Department of Computer Science

# Programming a remote controllable realtime FM audio synthesizer in Rust

## Masterseminar

**Andreas Linz**
<small>[alinz+masterthesis@klingt.net](mailto:alinz+masterthesis@klingt.net)
Leipzig / December 12th, 2016</small>

---
<!-- page_number: true -->

1. Introduction
2. Objectives
3. Basics
4. Technical Part
5. Experiments
6. Results
7. Outlook
8. Summary

---
# Motivation

- always been interested in audio hardware and musical synthesizers (DIY loudspeaker hobbyist)
- building a synthesizer is a great way to learn digital signal processing techniques
- development of real-time audio software involves to overcome many interesting obstacles
	- synchronization and timing problems
	- numerical issues

---
# Mission

- develop a fully functional real-time software synthesizer
- multi-oscillator and polyphonic
- supports frequency modulation synthesis (FM)
- good audio quality
- controllable with common music hardware

---
# Programming Language Requirements

- deterministic execution speed $\rightarrow$ no garbage collection, minimal runtime
- efficient C foreign function interface (FFI)

---
# Rust

- guarantees thread safety, e.g. no data races
- also memory safe, e.g. no segfaults
- functional programming features: iterators, algebraic data types, ...
- abstractions without runtime cost
- allows to write efficient C bindings

---
# Musical Instrument Digital Interface (MIDI)

- hardware interconnection scheme and method for data communication
- MIDI protocol: "standardized way for transmitting musical control information"
- MIDI messages: press of a (piano) key, knob turn, clock speed change, etc.
- fairly old (1981) and limited payload resolution (7bit or 14bit)
- available in nearly every piece of music hardware

---
# MIDI Pitch

- encoded as 7-bit $\rightarrow$ 128 pitches and $\approx{}10$ octaves
- chromatic western music scale 12 pitches per octave
- ratio between pitches $2^{1/12}$
- octave interval is equivalent to a doubling/halving in frequency
- frequencies for each pitch derived from reference pitch
- Concert A MIDI note 60 default tuning 440 Hz

---
# Open Sound Control (OSC)

- invented by *UC Berkeley Center for New Music and Audio Technology* in 2009
- open, transport-independent, message-based protocol, high-resolution types >=32-bit int/float
- "high-speed network replacement for MIDI" (UDP as transport-layer)
- not limited to musical control information
- URL-style address scheme for control mappings, e.g. `/filter/1/cutoff`

---
# Synthesizer Fundamentals

- Oscillator outputs period waveform at specific frequency
	- parameters: amplitude, frequency, phase, waveform
- multiple oscillators per voice
- each voice plays a single note
- polyphonic: multiple voices at a time
- synthesis techniques:
	- additive, subtractive, FM, ...

---
# Basic Waveforms

![50%](imgs/basic-waveforms.png)

---
# Additive and Subtractive Synthesis

- additive: separate sinusoidal oscillators to generate a complex sound from its partials
	- direct application of Fourier series
	- very CPU intensive, one oscillator per partial
- subtractive: start with a spectrally rich signal and remove parts of the spectrum with a filter
	- can be implemented very efficiently
	- most common synthesis technique

---
# FM Synthesis

![50% center](imgs/fm-operator.png)

---
![50% center](imgs/fm-grid.png)

---
# Architecture
![60%](imgs/architecture.png)

---
# Non-linearity of Human Hearing

- intensity of a sound is perceived logarithmically
- ratio between two sound intensities is important
- measured in decibel, dimension-less unit
- signal energy: $10\log_{10}\left(\frac{a}{b}\right)$
- signal power:  $20\log_{10}\left(\frac{a}{b}\right)$

---
# Envelope Generators

- sound is not static, changes over time (amplitude, spectrum)
- not sufficient to linearly ramp between values (not a smooth change in perceived loudness)
- envelope stages exponential (single-pole recursive filter)

![](imgs/adsr.png)

---
# Aliasing

![50%](imgs/aliasing.png)

---
- Nyquist frequency: $f_{Ny} = f_s / 2$

![60%](imgs/foldover.png)

---
# Fourier Series

- $e^{i\phi} = \cos(\phi)+i\sin(\phi)$
- $x_\text{saw}(t) = \sum^{\infty}_{n=-\infty,\;n\neq{}0} -1^n \frac{e^{-i\,2\pi\,n\,t}}{n\pi}$

![40%](imgs/fourier-series-sqr.png)

---
# Oscillators and Waveform Synthesis

- Ideal-bandlimited methods without harmonics above Nyquist freq., e.g. additive or wavetable synthesis
- Quasi-bandlimited methods with low aliasing, e.g. BLIT and BLEP
- Alias-supressing methods, e.g. oversampling and filtering of trivial waveform generators

---

# Block Diagram of a Generic Oscillator

- phase $\phi[t] = \left(\phi_0 / 2\pi\right) t$

![](imgs/oscillator-block-diagram.png)

---
# Trivial Waveform Generation

- sample ideal waveforms without bandlimiting
- spectral tilt of $\approx$ 6 dB per octave for sawtooth and pulse waves $\rightarrow$ severe aliasing distortion
- triangle wave by integrating a pulse wave over time
- triangle wave $\approx$ 12 dB per octave (integration ≙ first-order lowpass)
	- usable with high oversampling

---
# Bandlimited Impulse Trains (BLIT)

- insert impulse at each discontinuity of the waveform function
- lowpass filter impulses $\rightarrow$ every impulse replaced with the impulse response (sinc function) of an ideal (rectangle) filter
	- IR infinite $\rightarrow$ window sinc function (BLIT-SWS)
	- store IR in lookup table
- numerically integrate impulse response
- infinte response, apply window function to sinc response

---
# Bandlimited Step (BLEP)

- improved BLIT algorithm
- removes numerical issues of BLIT (DC component)
- pre-integrate windowed sinc $\rightarrow$ step function
- mix in step at discontinuities

![](imgs/blep.png)

---

# Disadvantages of BLIT and BLEP

- CPU usage proportional to frequency
- not easily applicable for the generation of non-basic waveforms

---
# Wavetables

- can generate arbitrary spectra (waveforms)
- define waveform in frequency domain
 	- mirror spectrum to get real valued signal
	- use inverse FFT to convert into time domain
- single waveform cycle stored in a lookup-table
- a number (one per octave) of lookup-tables with decreasing number of harmonics
- suitable wavetable is selected at run-time based on fundamental frequency

---
# 
![20% center](imgs/saw-table.png)

---
# Wavetable Interpolation Error

![40% center](imgs/interpolation-error.png)

---
# Disadvantages of Wavetable Oscillators

- pulse width modulation not as easy to implement as in BLIT/BLEP
- high memory usage (but cheap CPU usage)

---
# Multi-Mode Filter

![30% center](imgs/filter-classification.png)

---

![](imgs/filter-resonance.png)

---
# Event Handling

---
# Latency

- hard to measure
- latency from input to sound card $<20 ms$ is okay
- can be approximated by:

$$
l = l_{in}+\frac{b_{syn}+b_{out}}{f_s}
$$

- $f_s$ sample rate
- $b_{syn}, b_{out}$ synthesizer and sound card buffer size
- $l_{in}$ input latency, depends on connection (wifi, USB, bluetooth, ...)

---

![](imgs/ytterbium-0.1.0-Saw-sweep.png)
![](imgs/ytterbium-0.1.0-Sine-sweep.png)

---

![](imgs/ytterbium-0.1.0-fm.png)

---

![](imgs/ytterbium-0.1.0-LP-filter.png)
![](imgs/ytterbium-0.1.0-Notch-filter.png)

---

# Summary

---
<!-- *page_number: false -->

<h1 style="font-size: 4em;"> Questions?</h1>

- OSC, MIDI
- additive-, subtractive-, FM-synthesis
- filter FIR/IIR
- oscillators: BLIT, BLEP, wavetable
- Rust