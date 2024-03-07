// Ctrl+Enter to run
// Ctl+Period to stop
(
s.waitForBoot({
	SynthDef("slice",{
		// posStart fractional (0-1)
		arg buf, posStart=0, dur=0.5, bpmOriginal = 120, bpmTarget = 120, combdelay = 0, gverb = 0, lpf = 20000, hpf = 20, pan = 0;
		var snd;
		var phase;
		var rate;
		var xfade = 0.01; // 10 milliseconds crossfade

		rate = BufRateScale.ir(buf) * bpmTarget / bpmOriginal;

		phase = Phasor.ar(trig: 1,
			rate: rate,
			start: posStart*BufFrames.ir(buf),
			end: BufFrames.ir(buf),
			resetPos: posStart*BufFrames.ir(buf),
		).poll;
		snd = BufRd.ar(numChannels:2,
			bufnum: buf,
			phase: phase,
			loop: 1,
			interpolation: 4,
		);

		snd = snd * EnvGen.ar(Env.new([0,1,1,0],[xfade,dur-xfade,xfade]),doneAction:2);

		snd = SelectX.ar(combdelay,[snd, snd +
			Pan2.ar(CombN.ar(snd[0], 0.02, Rand(0.01,0.06), Rand(1,2)),-1) +
			Pan2.ar(CombN.ar(snd[1], 0.02, Rand(0.01,0.06), Rand(1,2)),1)
		]);

		snd = SelectX.ar(gverb,[snd,FreeVerb2.ar(snd[0],snd[1],1,0.9,0.1)]);

		snd = RLPF.ar(snd, lpf, 0.6);
		snd = RHPF.ar(snd, hpf, 0.65);

		snd = Balance2.ar(snd[0],snd[1],pan);

		//snd = snd * MouseY.kr(-96,0).dbamp;

		Out.ar(3, snd);
	}).add;

	s.sync;
	SynthDef("rhubarb",{
		arg note=60,detune=0.02,dur=1;
		var snd;
		var env;
		var freq = [note+Rand(detune.neg,detune),note+Rand(detune.neg,detune),note+Rand(detune.neg,detune)].midicps;
		// SinOsc SinOscFB Saw LFTri VarSaw
		snd = LFTri.ar(freq);
		snd = RLPF.ar(snd, freq*10);
		snd = Splay.ar(snd);
		env = EnvGen.ar(Env.new([0,1,1,0],[0.1,dur,0.1]),doneAction:2);
		Out.ar(0,snd * 24.neg.dbamp * env);
	}).add;
	s.sync;
	SynthDef("main",{
		var snd, sndDrums;
		var rev;
		var drumAmp;
		snd = In.ar(0,2);
		sndDrums = In.ar(3,2);

		// we can do main effects on the total sound
		 rev = FreeVerb2.ar(snd[0],snd[1],0.5,0.9,0.2);
		//rev = Fverb.ar(snd[0],snd[1],200,tail_density: LFNoise2.kr(1/3).range(50,90),decay: LFNoise2.kr(1/3).range(50,70));

		snd = SelectX.ar(MouseY.kr(),[snd,rev]);


		drumAmp = Amplitude.kr(Mix.new(sndDrums)).poll;
		//snd = snd * Clip.kr(1.0-drumAmp,0.1,1);
	    snd = Compander.ar(snd, sndDrums*MouseX.kr(0,2), 0.05,1,1,0.1);

		//snd = snd + (sndDrums*12.neg.dbamp);

		snd = RHPF.ar(snd,60);

		ReplaceOut.ar(0,snd);
	}).add;
	s.sync;
	//Synth("rhubarb",[\note,60,\dur,3]);


	b = Buffer.read(s,thisProcess.nowExecutingPath.dirname++"/drums_bpm120.flac",action:{
		"buffer loaded!".postln;
	});

	s.sync;

	Routine{
		var bpmOriginal = 120;
		var bpmTarget = 175;
		Synth.tail(s, "main");
		Pbind(
			\instrument, "rhubarb",
			\detune, Pseq([0.1,0.05,0.02],inf),
			\note, Pseq([
				[62-24,62, 66, 69-12],   // D, 2 beats
				[54-24,54, 57, 61],  // F#min, 4 beats
				[54, 57, 61, 64], // F#min7, 2 beats
				[61, 64, 68-12, 71-12],  // C#min7, 2 beats
				[62, 66-12, 69-12],  // D, 4 beats
				[62, 66, 69-12],   // D, 2 beats
				[54, 57, 61],  // F#min, 4 beats
				[54, 57, 61, 64], // F#min7, 2 beats
				[61, 64, 68-12, 71-12],  // C#min7, 2 beats
				[62, 66-12, 69-12],  // D, 4 beats
			],inf),
			\dur, Pseq([
				2,4,2,2,4,2,4,2,2,4,
			],inf),
		).play;

		Pbind(
			\instrument, \slice,
			\posStart, Pseq([
				Pseq((0..15),1),
				Prand([1,2,3,4],1),
			]/16,inf),
			\dur, Pseq([1,1,1,0.1,0.1,0.1,0.25,1,1,1,1],inf)*60 / bpmTarget,
			\bpmOriginal, bpmOriginal,
			\bpmTarget, bpmTarget,
			\combdelay, Prand([0,0,0,0,0,1],inf),
			\gverb, Prand([0,0,0,0,0,0.5,1],inf),
			\lpf, Pwhite(90,120).midicps,
			\hpf, Pwhite(20,150),
			\pan, Pseq([
				Pseq([0],4),
				Prand([-0.2,0.2],8),
				Prand([0.1,-0.1],8),
			],inf),
		).play;
	}.play;

});
)