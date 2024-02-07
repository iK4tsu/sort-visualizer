module engine;

import core.atomic;
import core.stdc.stdlib;
import std.conv;
import std.experimental.logger;

import bindbc.sdl;
import bindbc.opengl.bind;
import bindbc.opengl.gl;
import dlib;

import renderer;
import line;

enum uint FREQUENCY = 96_000;
__gshared uint TONE;
__gshared uint phase;

class Engine
{
public:
	static Engine start()
	{
		if (_instance !is null) return instance;
		else {
			auto e = new Engine();
			_instance = e;
		}

		scope(success) instance.running = true;

		  // ==================
		 // Initialize SDL lib
		// ==================

		SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0
			? errorf("Failed to initialize SDL: %s", SDL_GetError())
			: info("SDL successfully initialized.");

		infof("SDL VERSION [%s]", sdlSupport);
		scope(failure) SDL_Quit();


		  // ===============
		 // Create a Window
		// ===============

		instance._window = SDL_CreateWindow(
			"Sort Visualizer",
			SDL_WINDOWPOS_CENTERED,
			SDL_WINDOWPOS_CENTERED,
			1280, 720,
			SDL_WindowFlags.SDL_WINDOW_OPENGL
			| SDL_WindowFlags.SDL_WINDOW_SHOWN
		);

		instance.window is null
			? errorf("Failed to create window: %s", SDL_GetError())
			: infof("Window created with success.");
		scope(failure) SDL_DestroyWindow(instance.window);

		instance.context = SDL_GL_CreateContext(instance.window);
		auto support = loadOpenGL();

		SDL_GL_MakeCurrent(instance.window, &instance.context);
		infof("OpenGL loaded [%s]", support);

		glClearColor(0.05, 0.055, 0.045, 1);
		glViewport(0,0,1280,720);
		SDL_GL_SetSwapInterval(0);


		  // =============
		 // Prepare sound
		// =============

		SDL_AudioSpec want, have;

		want.freq = FREQUENCY;
		want.format = AUDIO_U16SYS;
		want.channels = 2;
		want.samples = 4096;
		want.callback = &onSound;

		if (SDL_OpenAudio(&want, &have) != 0)
		{
			error("Failed to open audio");
			exit(EXIT_FAILURE);
		}

		info("Audio opened");
		SDL_PauseAudio(0);

		return instance;
	}


	import sortable;
	void loopSort(Sortable sortable)
	{
		renderer = new Renderer(sortable.data.length.to!int, sortable.data.length.to!int);

		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		while (!sortable.over())
		{
			glClear(GL_COLOR_BUFFER_BIT);
			pollEvents();
			sortable.drawNextSort(renderer);
			SDL_GL_SwapWindow(_window);
			SDL_Delay(1);
		}

		foreach (d; sortable.data)
		{
			glClear(GL_COLOR_BUFFER_BIT);
			pollEvents();
			sortable.drawNextData(renderer);
			SDL_GL_SwapWindow(_window);
			SDL_Delay(1);
		}

		stop();
	}

	import std.traits : ReturnType;

	void loop(alias condition)()
		if (is(ReturnType!condition == bool))
	{
		while (condition())
		{

		}
	}


	void loop()
	{
		while (running) {
			SDL_Event e;
			if (SDL_PollEvent(&e) && e.type == SDL_EventType.SDL_QUIT) {
				stop();
				return;
			}

			// SDL_GL_SwapWindow(_window);
			SDL_Delay(10);
		}
	}


	void pollEvents(ref SDL_Event e)
	{
		while (SDL_PollEvent(&e)) {
				if (e.type == SDL_EventType.SDL_QUIT) {
					stop();
					return;
				}
				else if (e.type == SDL_EventType.SDL_WINDOWEVENT && e.window.event == SDL_WindowEventID.SDL_WINDOWEVENT_RESIZED)
				{
					glViewport(0, 0, e.window.data1, e.window.data2);
				}
			}
	}


	void pollEvents()
	{
		SDL_Event e;
		pollEvents(e);
	}


	void stop()
	{
		running = false;
		info("Exited loop.");

		TONE = 0;
		SDL_CloseAudio();
		info("Audio closed.");

		SDL_GL_DeleteContext(context);
		info("OpenGL window context deleted.");

		SDL_DestroyWindow(_window);
		info("Exited window.");

		SDL_Quit();
		info("Exited SDL.");


		info("Engine stopped with success.");
		exit(EXIT_SUCCESS);
	}


	static Engine instance() { return cast(Engine) _instance; }
	SDL_Window* window() { return _window; }

private:
	this() {}

	SDL_Window* _window;
	SDL_GLContext context;
	SDL_AudioDeviceID dev;
	Renderer renderer;
	bool running;
	static Engine _instance;
}


extern(C) nothrow
{
	void onSound(void* data, ubyte* _stream, int len)
	{
		short* stream = cast(short*) _stream;
		uint length = len/2;

		if (TONE == 0) stream[0 .. length] = 0;
		else
		{
			for (uint i = 0; i < length; i++)
			{
				stream[i] = phase % TONE < TONE/2 ? 0 : 0x2000;
				phase++;
			}
		}
	}
}
