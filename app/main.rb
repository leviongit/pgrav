$gtk.reset seed: Time.now.to_i

include MatrixFunctions

PARTICLE_RES = 64
HALF_OF_PSIZE = PARTICLE_RES / 2.0
FULL_SAT = 256.0
SCALE_TO_FULL_SAT = HALF_OF_PSIZE / FULL_SAT

PARTICLE_SIZE = 16

def init_make_particle_rt(args)
  args.outputs[:"particle"].tap do |rt|
    rt.w = PARTICLE_RES
    rt.h = PARTICLE_RES
    # rt.sprites << { x: 0, y: 0, w: rt.w, h: rt.h, g: 0, b: 0 }
    rt.sprites << PARTICLE_RES.map_with_ys(PARTICLE_RES) do |x, y|
      xx = x + 0.5
      yy = y + 0.5
      v = FULL_SAT - (Math.sqrt(((xx - HALF_OF_PSIZE) * (xx - HALF_OF_PSIZE)) + ((yy - HALF_OF_PSIZE) * (yy - HALF_OF_PSIZE))) / SCALE_TO_FULL_SAT)
      { x: x, y: y, path: :pixel, w: 1, h: 1, a: v }
    end
  end
end

def init_make_particles(args, count = 200)
  args.state.particles = count.times.map do
    prim_rot = rand * Math::PI
    sndr_rot = prim_rot + (Math::PI / 3)
    tert_rot = sndr_rot + (Math::PI / 3)
    mass = rand(500) * 10000 # kg
    {
      x: rand(1280),
      y: rand(720),
      w: PARTICLE_SIZE * 10 * (mass / (5000 * 1000)),
      h: PARTICLE_SIZE * 10 * (mass / (5000 * 1000)),
      r: (Math.sin(prim_rot) + 1) * 128,
      g: (Math.sin(sndr_rot) + 1) * 128,
      b: (Math.sin(tert_rot) + 1) * 128,
      path: :particle,
      v: vec2(*-> { th = rand * Math::PI * 2; [Math.cos(th), Math.sin(th)] }[]),
      mass: mass
    }
  end
end

def init(args)
  init_make_particle_rt(args)
  init_make_particles(args, 25)
end

def render(args)
  args.outputs.background_color = [16] * 3

  args.outputs.sprites.concat(args.state.particles)
end

def calc(args)
  Fn.each args.state.particles do |part|
    sum = vec2(0, 0)

    Fn.each args.state.particles do |r|
      next if r == part

      dv = (vec2(-part.x, -part.y)) + (vec2(r.x, r.y))
      mv = distance(dv, vec2(0, 0))
      next if mv == 0
      nv = dv * vec2(*[(1 / mv)] * 2)

      sum += (nv * vec2(*[1e-3 * ((part.mass * r.mass) / ((mv * 10) ** 2))] * 2))
    end

    part.v.x += (sum.x / (part.mass))
    part.v.y += (sum.y / (part.mass))
  end

  args.state.particles.map! do |part|
    { **part, **(vec2(part[:x], part[:y]) + part.v) }
  end
end

def input(args)
  args.outputs.screenshots << {
    x: 0,
    y: 0,
    w: 1280,
    h: 720,
    path: "screenshot-t#{"%06d" % (args.tick_count)}.png",
  } if args.inputs.keyboard.key_down.p
end

def tick(args)
  init(args) if args.tick_count == 0
  calc(args)
  render(args)
  input(args)

  # puts60 args.outputs.sprites
end
