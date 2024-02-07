import std.algorithm;
import std.array;
import std.conv;
import std.random;
import std.range;

import dlib;

import engine;
import line;
import radix;

void main()
{
	Engine.start().loopSort(new Radix(
		800
			.iota
			.array
			.randomShuffle
			.enumerate
			.map!(a => Line(vec3([0f,1f,1f]),vec4(a[0], 0f, a[0], a[1] + 1f)))
			.array
	));
}
