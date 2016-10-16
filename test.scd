// let's say there is a directory "pat" with *.scd files where each file contains, for example:
// test.scd 
{ |dict,loc| // recieve global dict
	loc = ( //and define local(this file) dict, but if don't need it - just return anonymously
		selector: { |self, ev| self.at([\p1,\p2].choose).fn(ev) }, // sample selector
		p1: ( // some object 
			fn: { |self, ev| // recieve self and some args
				Pbind(*[ // return something
					instrument: \default,
					delta: ev.delta/8,
					amp: Pseq((0.3..0.8).scramble, inf),
					octave: self.state.next
				])
			}, 
			state: Pseq((3..6), inf).asStream  // i.e. object attribute
		),
		p2: ( // altered version of p1
			fn: { |self, ev|  // able to access both local and global dict
				Pbindf(loc.p1.fn(ev), \mtranspose, self.state.next) // * dict.some_name.some_key.fn(ev),
			},
			state: Pseq((1..3),inf).asStream
		)
		// etc..
	)
}

// and while working in file which resides above directory where test.scd located
(
var dict = "pat/*.scd".resolveRelative.pathMatch.inject((), { |d, i| // create dictionary
	d[i.basename.splitext[0].asSymbol] = i.load.(d) 
});
dict.test.p2.fn((delta:2)).play;
// or
Pspawn(
	Pbind(*[
		method:\par,
		delta:Pseq((1..4),inf),
		pattern:Pfunc({ |ev|  // choose some random pattern from dict
			Pfindur(ev.delta, dict.values.choose.selector(ev)) 
		})
	]);
).play
)