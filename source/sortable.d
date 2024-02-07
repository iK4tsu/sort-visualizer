module sortable;

import std.conv;

import engine;
import line;
import renderer;

import dlib;

abstract class Sortable
{
public:
	this(Line[] lines) { this.data = lines; }

	abstract void drawNextSort(Renderer renderer);
	abstract bool over();
	void drawNextData(Renderer renderer)
	{
		scope(exit) idata++;
		TONE = FREQUENCY / (data[idata].points[3].to!uint);
		data[idata].color = vec3([1f,0f,0f]);
		renderer.drawLines(data);
		data[idata].color = vec3([0f,1f,0f]);
	}


	Line[] data;
	protected size_t idata;
}
