module radix;

import std.algorithm;
import std.array;
import std.conv;
import std.range;

import engine;
import line;
import renderer;
import sortable;

import bindbc.opengl;
import bindbc.sdl;
import dlib;

class Radix : Sortable
{
public:
	this(Line[] lines) {
		super(lines);
		bucket = new Line[lines.length];
		counter = new size_t[10];
		exp = 1;
		max = data.maxElement!"a.points[3]".points[3].to!int;
	}

	override
	bool over()
	{
		return !(max / exp > 0);
	}

	override
	void drawNextSort(Renderer renderer)
	{
		scope(exit) {
			if (i+1 < data.length) i++;
			else {
				counter = counter.cumulativeFold!"a+b".array;
				import std.stdio;
				data.reverse.each!((value) {
					// writefln!"v: %s | i: %s"(value.points[3], (value.points[3].to!size_t / exp ) % 10);
					auto i = --counter[(value.points[3].to!size_t / exp ) % 10];
					value.points[0] = i;
					value.points[2] = i;
					bucket[i] = value;
				});
				data = bucket.dup;
				counter = 0.repeat!size_t(10).array;

				i = 0;
				exp*=10;
			}
		}

		// push v to correct bucket
		counter[(data[i].points[3].to!size_t / exp) % 10]++;

		TONE = FREQUENCY / (data[i].points[3].to!uint);
		data[i].color = vec3([1f,0f,0f]);
		renderer.drawLines(data);
		data[i].color = vec3([0f,1f,1f]);
	}

private:
	Line[] bucket;
	size_t[] counter;
	size_t curIndex;
	size_t exp;
	size_t i;
	int max;
}
