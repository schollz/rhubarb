(
s.waitForBoot({
	Routine {
		SynthDef("slice",{
			arg buf, frames = 1000, bpmOriginal=120, bpmNew=120,posStart=0,dur=0.125,lpf=17000, hpf=20, speed=1, verb=0, delay=0, gating=1;
			var xfade = 0.01;
			var snd;
			var rate;
			var phase;
			rate = bpmNew/bpmOriginal*BufRateScale.ir(buf) * speed;
			phase = Phasor.ar(1,rate,posStart*frames,frames,posStart * frames);
			snd = BufRd.ar(2, buf, phase, 1.0, 4);
			snd = snd * EnvGen.ar(Env.new([0,1,1,0],[xfade,(dur-xfade)*(gating),xfade]),doneAction:2);
			snd = RLPF.ar(snd,lpf,0.707);
			snd = RHPF.ar(snd,hpf,0.303);
			snd = SelectX.ar(delay,[snd,snd+CombC.ar(snd,2,Rand(0.01,0.06),Rand(1,2))]);
			snd = FreeVerb2.ar(snd[0],snd[1],verb,0.8,0.1);
			Out.ar(0,snd);
		}).add;
		SynthDef("saw",{
			arg note,dur=2;
			var xfade=0.2;
			var freq= [note+rrand(-0.05,0.05),note+Rand(-0.05,0.05),note+Rand(-0.05,0.05)].midicps;
			var snd  = Saw.ar(freq);
			snd = MoogFF.ar(snd,freq*Rand(2,4),2);
			snd = Splay.ar(snd);
			snd = snd * EnvGen.ar(Env.new([0,1,1,0],[xfade,(dur-xfade),xfade*rrand(1,10)]),doneAction:2);
			Out.ar(3,snd);
		}).add;
		SynthDef("out",{
			var snd;
			var drums = In.ar(0,2);
			var synth = In.ar(3,2);
			var amp;
			drums = Compander.ar(drums,drums,thresh: 0.9,slopeBelow: 1,slopeAbove: 0.5,clampTime:  0.01,relaxTime:  0.01
			)*4.dbamp;
			drums = drums.tanh;
			amp = Amplitude.ar(drums,0.1,0.1);
			drums = drums*MouseY.kr(-96,0).dbamp;
			//synth = AnalogTape.ar(synth,0.5,0.4,0.7);
			//drums = AnalogTape.ar(drums,0.9,0.7,0.8,2);
			//synth = SelectX.ar(LFNoise2.kr(1/3).range(0.5,0.8),[synth,Fverb.ar(synth[0],synth[1],200,tail_density: LFNoise2.kr(1/3).range(50,90),decay: LFNoise2.kr(1/3).range(50,70))]);
			synth = SelectX.ar(LFNoise2.kr(1/3).range(0.5,0.8),[synth,FreeVerb2.ar(synth[0],synth[1],1,0.9,0.1)]);
			synth = CompanderD.ar(in: synth,control: drums,thresh: 0.8,slopeBelow: 1.0,slopeAbove: 0.1,clampTime: 0.01,relaxTime: 0.1);
			snd = (synth*0.neg.dbamp*(1-amp)) + (drums*2.neg.dbamp);
			ReplaceOut.ar(0,snd*12.neg.dbamp);
		}).add;
		b=Buffer.read(s,thisProcess.nowExecutingPath.dirname++"/drums_bpm120.flac");
		s.sync;
		Routine{
			var bpmOriginal = 120*1.5;
			var bpmNew = 175;
			Synth.tail(s,"out");
			Pbind(
				\instrument, \saw,
				\dur, Pseq([2,4,2,2,4,2,4,2,2,4],inf)*60/bpmNew*2,
				\note, Pseq([
					[62, 66, 69-12],   // D, 2 beats
					[54, 57, 61],  // F#min, 4 beats
					[54, 57, 61, 64], // F#min7, 2 beats
					[61, 64, 68-12, 71-12],  // C#min7, 2 beats
					[62, 66-12, 69-12],  // D, 4 beats
					[62, 66, 69-12],   // D, 2 beats
					[54, 57, 61],  // F#min, 4 beats
					[54, 57, 61, 64], // F#min7, 2 beats
					[61, 64, 68-12, 71-12],  // C#min7, 2 beats
					[62, 66-12, 69-12],  // D, 4 beats
				],inf),
			).play;
			Pbind(
				\instrument, \slice,
				\bpmOriginal, bpmOriginal,
				\bpmNew, bpmNew,
				\frames, b.numFrames,
				\buf, b.bufnum,
				\posStart, Pseq([
					Pseq((0..7),8),
					Prand((0..15),4),
					Pseq((8..15),8),
					Prand((0..15),4),
				],inf)/16,
				\dur, Pseq([
					Pseq([1, 1, 1, 1], 3),
					Pseq([0.5,0.5, 1, 1, 4], 1),
					Pseq(0.125!4, 1),
					Pseq([1, 1, 1, 1], 3),
					Pseq([0.5,0.5, 1, 1, 2, 4, 6], 1),
				],inf)*60/bpmNew,
				\lpf, Pwhite(90,120).midicps,
				\hpf, Pwhite(20,150),
				\speed, Prand([1,1,1,1,1,1,1,1,1,0.25,-1],inf),
				\verb, Prand([0,0,0,0,0,0.5,0,0.25,1],inf),
				\delay, Prand([0,0,0,0,0,0.25,0.1,1],inf),
				\gating, Prand([1,1,1,1,0.9],inf),
			).play;
		}.play;
	}.play;
});
)