module renderer;

import core.stdc.stdlib;
import std.experimental.logger;
import std.string;

import bindbc.opengl;
import dlib;

import line;

class Renderer
{
	this(int width, int height)
	{
		auto errorShader = (uint shader) {
			int success;
			glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

			if (!success)
			{
				// success is now the shader type
				glGetShaderiv(shader, GL_SHADER_TYPE, &success);
				string type = success == GL_VERTEX_SHADER ? "VertexShader" : "FragmentShader";

				// success is now error log length
				glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &success);
				char[] buff = new char[success]; // buffer of info log length
				glGetShaderInfoLog(shader, success, null, buff.ptr);

				errorf("Failed to compile shader [%s]: %s", type, buff);
				exit(EXIT_FAILURE);
			}
		};

		auto errorProgram = (uint program) {
			int success;
			glGetProgramiv(program, GL_LINK_STATUS, &success);

			if (!success)
			{
				// success is now error log length
				glGetProgramiv(program, GL_INFO_LOG_LENGTH, &success);
				char[] buff = new char[success]; // buffer of info log length
				glGetProgramInfoLog(program, success, null, buff.ptr);

				error("Failed to link program: %s", buff);
				exit(EXIT_FAILURE);
			}
		};


		  // =============
		 // Vertex Shader
		// =============

		auto vs = glCreateShader(GL_VERTEX_SHADER);
		scope(exit) glDeleteShader(vs);


		string shader = q{
			#version 330 core
			layout(location = 0) in vec2 pos;

			uniform mat4 m, v, p;

			void main() {
				gl_Position = p*v*m*vec4(pos.xy, 0.0, 1.0);
			}
		};

		glShaderSource(vs, 1, [shader.toStringz].ptr , null);

		info("Compiling Vertex Shader...");
		glCompileShader(vs);
		errorShader(vs);


		  // ===============
		 // Fragment Shader
		// ===============

		auto fs = glCreateShader(GL_FRAGMENT_SHADER);
		scope(exit) glDeleteShader(fs);

		shader = q{
			#version 330 core

			uniform vec3 color;
			out vec4 fcolor;

			void main() {
				fcolor = vec4(color, 1.0);
			}
		};

		glShaderSource(fs, 1, [shader.toStringz].ptr , null);

		info("Compiling Fragment Shader...");
		glCompileShader(fs);
		errorShader(fs);


		  // =======
		 // Program
		// =======

		program = glCreateProgram();
		glAttachShader(program, vs);
		glAttachShader(program, fs);
		glLinkProgram(program);
		errorProgram(program);


		  // =============
		 // Buffers & VAO
		// =============

		glGenVertexArrays(1, &vertexArray);
		glGenBuffers(1, &vertexBuffer);


		  // ===============
		 // Camera settings
		// ===============

		p = orthoMatrix(0, width, 0, height, -100f, 100f) * scaleMatrix(vec3(0.5,0.9,0));
		v = translationMatrix(vec3(0f,0f,0f));
	}


	~this()
	{
		glDeleteVertexArrays(1, &vertexArray);
		glDeleteBuffers(1, &vertexBuffer);
		glDeleteProgram(program);
	}


	void drawLines(in Line[] lines)
	{
		foreach (const ref l; lines)
		{
			this.drawLine(l);
		}
	}


	void drawLine(Line l)
	{
		glUseProgram(program);
		glUniform3fv(glGetUniformLocation(program, "color"), 1, l.color.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "p"), 1, false, p.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "v"), 1, false, v.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "m"), 1, false, translationMatrix(vec3(l.points.x, l.points.y, 0f)).arrayof.ptr);

		glBindVertexArray(vertexArray);
		glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, l.points[].length*float.sizeof, l.points[].ptr, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 2, GL_FLOAT, false, 2*float.sizeof, cast(void*)0);
		glEnableVertexAttribArray(0);

		glBindVertexArray(vertexArray);
		glDrawArrays(GL_LINES, 0, 2);
		glBindVertexArray(0);
	}


	void draw()
	{
		  // ==============
		 // Prepare render
		// ==============

		  // ===============
		 // Prepare shaders
		// ===============

		glUseProgram(program);
		glUniform3fv(glGetUniformLocation(program, "color"), 1, color.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "p"), 1, false, p.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "v"), 1, false, v.arrayof.ptr);
		glUniformMatrix4fv(glGetUniformLocation(program, "m"), 1, false, translationMatrix(vec3(vertices.x, vertices.y, 0f)).arrayof.ptr);

		  // ===============
		 // Prepare buffers
		// ===============

		glBindVertexArray(vertexArray);
		glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, vertices.arrayof.length*float.sizeof, vertices.arrayof.ptr, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 2, GL_FLOAT, false, 2*float.sizeof, cast(void*)0);
		glEnableVertexAttribArray(0);


		  // ================
		 // Bind Draw Unbind
		// ================

		glBindVertexArray(vertexArray);
		glDrawArrays(GL_LINES, 0, 2);
		glBindVertexArray(0);
	}


	vec4 vertices;
	vec3 color;
private:
	uint program;
	uint vertexBuffer;
	uint vertexArray;
	mat4 p;
	mat4 v;
}
