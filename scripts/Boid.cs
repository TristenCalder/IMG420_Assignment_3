using Godot;
using System.Collections.Generic;

public partial class Boid : Node2D
{
	// Tunables
	[Export] public float MaxSpeed { get; set; } = 180f;
	[Export] public float MaxForce { get; set; } = 240f;
	[Export] public float Perception { get; set; } = 120f;
	[Export] public float SeparationRadius { get; set; } = 48f;

	[Export] public float SepW { get; set; } = 1.6f;
	[Export] public float AliW { get; set; } = 1.0f;
	[Export] public float CohW { get; set; } = 1.0f;
	[Export] public float BoundsW { get; set; } = 1.2f;
	[Export] public float FollowW { get; set; } = 0.8f;

	public Vector2 Vel;

	// Simple built-in triangle so you don't need a Sprite/Polygon2D
	private static readonly Vector2[] TRI =
	{
		new Vector2(0, -6),
		new Vector2(-4, 4),
		new Vector2(4, 4)
	};

	public override void _Ready()
	{
		Vel = Vector2.Right.Rotated(GD.Randf() * Mathf.Tau) * (MaxSpeed * 0.6f);
		SetProcess(true);
		QueueRedraw();
	}

	public override void _Process(double delta)
	{
		float dt = (float)delta;
		Vector2 acc = Vector2.Zero;

		// Neighbor scan
		var neighbors = GetTree().GetNodesInGroup("boids");
		int n = 0;
		Vector2 sumPos = Vector2.Zero, sumVel = Vector2.Zero, sep = Vector2.Zero;

		foreach (var node in neighbors)
		{
			if (node == this) continue;
			var b = (Boid)node;
			float d = GlobalPosition.DistanceTo(b.GlobalPosition);
			if (d > Perception) continue;

			n++;
			sumPos += b.GlobalPosition;
			sumVel += b.Vel;

			if (d < SeparationRadius && d > 0.001f)
				sep += (GlobalPosition - b.GlobalPosition).Normalized() / Mathf.Max(d, 1f);
		}

		if (n > 0)
		{
			// Alignment
			var ali = (sumVel / n).LimitLength(MaxSpeed) - Vel;
			acc += ali.LimitLength(MaxForce) * AliW;

			// Cohesion
			var center = sumPos / n;
			var coh = (center - GlobalPosition).Normalized() * MaxSpeed - Vel;
			acc += coh.LimitLength(MaxForce) * CohW;

			// Separation
			var sepf = sep == Vector2.Zero ? Vector2.Zero : sep.Normalized() * MaxSpeed - Vel;
			acc += sepf.LimitLength(MaxForce) * SepW;
		}

		// Soft bounds bias
		acc += SoftBoundsForce() * BoundsW;

		// Follow Bird (FlockManager.Target)
		var fm = GetParent() as FlockManager;
		if (fm != null && fm.Target.HasValue)
		{
			var seek = (fm.Target.Value - GlobalPosition).Normalized() * MaxSpeed - Vel;
			acc += seek.LimitLength(MaxForce) * FollowW;
		}

		// Integrate
		Vel = (Vel + acc * dt).LimitLength(MaxSpeed);
		GlobalPosition += Vel * dt;
		Rotation = Vel.Angle();

		// Gentle wrap to keep them visible
		SoftBoundsWrap();
	}

	private Vector2 SoftBoundsForce()
	{
		var vp = GetViewportRect().Size;
		var p = GlobalPosition;
		Vector2 f = Vector2.Zero;
		float m = 64f, steer = MaxForce * 0.5f;

		if (p.X < m) f.X += steer; else if (p.X > vp.X - m) f.X -= steer;
		if (p.Y < m) f.Y += steer; else if (p.Y > vp.Y - m) f.Y -= steer;

		return f;
	}

	private void SoftBoundsWrap()
	{
		var vp = GetViewportRect().Size;
		var p = GlobalPosition;

		if (p.X < -10) p.X = vp.X + 10;
		if (p.X > vp.X + 10) p.X = -10;
		if (p.Y < -10) p.Y = vp.Y + 10;
		if (p.Y > vp.Y + 10) p.Y = -10;

		GlobalPosition = p;
	}

	public override void _Draw()
	{
		DrawPolygon(TRI, new Color[] { Colors.White, Colors.White, Colors.White });
	}
}
